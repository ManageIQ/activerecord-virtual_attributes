module ActiveRecord
  module VirtualAttributes
    # VirtualDelegate is the same as delegate, but adds sql support, and a default when a value is not found
    #
    # Model.belongs_to :association
    # Model.virtual_delegate :field1, :field2, to: :association
    #
    # Model.select(:field1) # now works
    module VirtualDelegates
      extend ActiveSupport::Concern

      module ClassMethods
        #
        # Definition
        #

        def virtual_delegate(*methods, to:, type:, prefix: nil, allow_nil: nil, default: nil, uses: nil, **options) # rubocop:disable Naming/MethodParameterName
          src_loc = caller_locations
          to = to.to_s
          if to.include?(".") && (methods.size > 1 || prefix)
            raise ArgumentError, 'Delegation only supports specifying a target method name when defining a single virtual method with no prefix'
          end

          if to.count(".") > 1
            raise ArgumentError, 'Delegation needs a single association. Supply keyword :to with only 1 period (e.g. delegate :hello, to: "greeter.greeting")'
          end

          # put method entry per method name.
          # This better supports reloading of the class and changing the definitions
          methods.each do |method|
            method_name, to, method = determine_method_names(method, to, prefix)

            # NOTE: delete_blank will remove a default of []. we only want to remove nils
            va_params = options.merge(:uses => uses, :through => to, :source => method, :default => default).delete_if { |_n, v| v.nil? }

            ActiveRecord::VirtualAttributes.deprecator.warn("virtual_delegate is deprecated in favor of virtual_attribute. Change to: #{name}.virtual_attribute #{method_name.inspect}, #{type.inspect}, #{va_params.map { |k, v| "#{k.inspect} => #{v.inspect}" }.join(", ")}", src_loc)
            virtual_attribute(method_name, type, **va_params)
          end
        end

        private

        # see activesupport module/delegation.rb
        # rubocop:disable Style/TernaryParentheses
        def define_delegate(method_name, method, to: nil, allow_nil: nil, default: nil) # rubocop:disable Naming/MethodParameterName
          location = caller_locations(2, 1).first
          file, line = location.path, location.lineno

          # Attribute writer methods only accept one argument. Makes sure []=
          # methods still accept two arguments.
          definition = (method =~ /[^\]]=$/) ? 'arg' : '*args, &block'
          default = default ? " || #{default.inspect}" : nil
          # The following generated method calls the target exactly once, storing
          # the returned value in a dummy variable.
          #
          # Reason is twofold: On one hand doing less calls is in general better.
          # On the other hand it could be that the target has side-effects,
          # whereas conceptually, from the user point of view, the delegator should
          # be doing one call.
          # NOTE: This is based upon ActiveSupport 6.0 delegate.rb, but we added has_attribute? and default
          if allow_nil
            method_def = <<-METHOD
              def #{method_name}(#{definition})
                return self[:#{method_name}]#{default} if has_attribute?(:#{method_name})
                _ = #{to}
                if !_.nil? || nil.respond_to?(:#{method})
                  _.#{method}(#{definition})
                end#{default}
              end
            METHOD
          else
            exception = %(raise Module::DelegationError, "#{self}##{method_name} delegated to #{to}.#{method}, but #{to} is nil: \#{self.inspect}")

            method_def = <<-METHOD
              def #{method_name}(#{definition})
                return self[:#{method_name}]#{default} if has_attribute?(:#{method_name})
                _ = #{to}
                _.#{method}(#{definition})#{default}
              rescue NoMethodError => e
                if _.nil? && e.name == :#{method}
                  #{exception}
                else
                  raise
                end
              end
            METHOD
          end
          method_def = method_def.split("\n").map(&:strip).join(';')
          module_eval(method_def, file, line)
        end
        # rubocop:enable Style/TernaryParentheses

        # Sometimes the `to` contains the column name target.column, split it up to the source method_name and target column
        # If `to` does specify the column name, `to` becomes the target (i.e.: association)
        #
        # @param column [Symbol|String] the name of the column
        # @param to [Symbol|String]
        # @param prefix [Boolean|Nil|Symbol]
        # @return [Symbol, Symbol, Symbol] method_name, relation, relation's column name
        def determine_method_names(column, to, prefix) # rubocop:disable Naming/MethodParameterName
          method_name = column = column.to_sym

          tos = to.to_s
          if tos.include?(".") # to => "target.method"
            to, column = tos.split(".").map(&:to_sym)
          end

          method_prefix = "#{prefix == true ? to : prefix}_" if prefix
          method_name = :"#{method_prefix}#{method_name}"

          [method_name, to.to_sym, column]
        end

        # @param col [String] attribute name
        # @param to_ref [Association] association from source class to target association
        # @return [Proc] lambda to return arel that selects the attribute in a sub-query
        # @return [Nil] if the attribute (col) can not be represented in sql.
        #
        # To generate a proc, the following cases must happen:
        #   - the column has sql (virtual_column with arel OR real sql attribute)
        #   - the association has sql representation (a real association has sql)
        #   - the association is to a single record (has_one or belongs_to)
        #
        #   See select_from_alias for examples

        def virtual_delegate_arel(col, to_ref)
          # Ensure the association is reachable via sql
          #
          # But NOT ensuring the target column has sql
          #   to_ref.klass.arel_attribute(col) loads the target classes' schema.
          #   This cascades and causing a race condition
          #
          # There is currently no way to propagate sql over a virtual association
          if reflect_on_association(to_ref.name) && (to_ref.macro == :has_one || to_ref.macro == :belongs_to)
            lambda do |t|
              src_model_id = arel_table[to_ref.join_foreign_key, t]
              blk = ->(arel) { arel.limit = 1 } if to_ref.macro == :has_one
              VirtualDelegates.select_from_alias(to_ref, col, to_ref.join_primary_key, src_model_id, &blk)
            end
          end
        end
      end

      # select_from_alias: helper method for virtual_delegate_arel to construct the sql
      # see also virtual_delegate_arel
      #
      # @param to_ref [Association] association from source class to target association
      # @param col [String] attribute name
      # @param to_model_col_name [String]
      # @param src_model_id [Arel::Attribute]
      # @return [Arel::Node] Arel representing the sql for this join
      #
      # example
      #
      #   for the given belongs_to class definition:
      #
      #     class Vm
      #       belongs_to :hosts #, :foreign_key => :host_id, :primary_key => :id
      #       virtual_delegate :name, :to => :host, :prefix => true, :allow_nil => true
      #     end
      #
      #   The virtual_delegate calls:
      #
      #     virtual_delegate_arel("name", Vm.reflection_with_virtual(:host))
      #
      #   which calls:
      #
      #     select_from_alias(Vm.reflection_with_virtual(:host), "name", "id", Vm.arel_table[:host_id])
      #
      #   which produces the sql:
      #
      #     SELECT to_model[col] from to_model where to_model[to_model_col_name] = src_model_table[:src_model_id]
      #     (SELECT "hosts"."name" FROM "hosts" WHERE "hosts"."id" = "vms"."host_id")
      #
      #   ----
      #
      #   for the given has_one class definition
      #
      #     class Host
      #       has_one :hardware
      #       virtual_delegate :name, :to => :hardware, :prefix => true, :allow_nil => true
      #     end
      #
      #   The virtual_delegate calls:
      #
      #     virtual_delegate_arel("name", Host.reflection_with_virtual(:hardware))
      #
      #   which at runtime will call select_from_alias:
      #
      #     select_from_alias(Host.reflection_with_virtual(:hardware), "name", "host_id", Host.arel_table[:id])
      #
      #   which produces the sql (ala arel):
      #
      #     #select to_model[col] from to_model where to_model[to_model_col_name] = src_model_table[:src_model_id]
      #     (SELECT "hardwares"."name" FROM "hardwares" WHERE "hardwares"."host_id" = "hosts"."id")
      #
      #   ----
      #
      #   for the given self join class definition:
      #
      #     class Vm
      #       belongs_to :src_template, :class => Vm
      #       virtual_delegate :name, :to => :src_template, :prefix => true, :allow_nil => true
      #     end
      #
      #   The virtual_delegate calls:
      #
      #     virtual_delegate_arel("name", Vm.reflection_with_virtual(:src_template))
      #
      #   which calls:
      #
      #     select_from_alias(Vm.reflection_with_virtual(:src_template), "name", "src_template_id", Vm.arel_table[:id])
      #
      #   which produces the sql:
      #
      #     #select to_model[col] from to_model where to_model[to_model_col_name] = src_model_table[:src_model_id]
      #     (SELECT "vms_sub"."name" FROM "vms" AS "vms_ss" WHERE "vms_ss"."id" = "vms"."src_template_id")
      #

      # Based upon ActiveRecord AssociationScope.scope
      def self.select_from_alias(to_ref, col, to_model_col_name, src_model_id)
        query = if to_ref.scope
                  to_ref.klass.instance_exec(nil, &to_ref.scope)
                else
                  to_ref.klass.all
                end

        src_model = to_ref.active_record
        to_table  = select_from_alias_table(to_ref.klass, src_model_id.relation)
        to_model_id = to_ref.klass.arel_table[to_model_col_name, to_table]
        to_column   = to_ref.klass.arel_table[col, to_table]
        arel = query.except(:select).select(to_column).arel
                    .from(to_table)
                    .where(to_model_id.eq(src_model_id))

        # :type is in the reflection definition (meaning it is polymorphic)
        if to_ref.type
          # get the class name (e.g. "Host")
          polymorphic_type = src_model.base_class.name
          arel = arel.where(to_ref.klass.arel_table[to_ref.type].eq(polymorphic_type))
        end

        yield arel if block_given?

        arel
      end

      # determine table reference to use for a sub query
      #
      # typically to_table is just the table used for the to_ref
      # but if it is a self join, then it will also have an alias
      def self.select_from_alias_table(to_klass, src_relation)
        to_table = to_klass.arel_table
        # if a self join, alias the second table to a different name
        if to_table.name == src_relation.name
          # use a table alias to not conflict with table name in the primary query
          to_table = to_table.alias("#{to_table.name}_sub")
        end
        to_table
      end
    end
  end
end
