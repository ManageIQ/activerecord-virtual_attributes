module ActiveRecord
  module VirtualAttributes
    module VirtualReflections
      extend ActiveSupport::Concern
      include ActiveRecord::VirtualAttributes::VirtualIncludes

      module ClassMethods

        #
        # Definition
        #

        def virtual_has_one(name, options = {})
          uses = options.delete(:uses)
          reflection = ActiveRecord::Associations::Builder::HasOne.build(self, name, nil, options)
          add_virtual_reflection(reflection, name, uses, options)
        end

        def virtual_has_many(name, options = {})
          define_method(:"#{name.to_s.singularize}_ids") do
            records = send(name)
            records.respond_to?(:ids) ? records.ids : records.collect(&:id)
          end
          uses = options.delete(:uses)
          reflection = ActiveRecord::Associations::Builder::HasMany.build(self, name, nil, options)
          add_virtual_reflection(reflection, name, uses, options)
        end

        def virtual_belongs_to(name, options = {})
          uses = options.delete(:uses)
          reflection = ActiveRecord::Associations::Builder::BelongsTo.build(self, name, nil, options)
          add_virtual_reflection(reflection, name, uses, options)
        end

        def virtual_reflection?(name)
          virtual_reflections.key?(name.to_sym)
        end

        def virtual_reflection(name)
          virtual_reflections[name.to_sym]
        end

        #
        # Introspection
        #

        def virtual_reflections
          (virtual_fields_base? ? {} : superclass.virtual_reflections).merge(_virtual_reflections)
        end

        def reflections_with_virtual
          reflections.symbolize_keys.merge(virtual_reflections)
        end

        def reflection_with_virtual(association)
          virtual_reflection(association) || reflect_on_association(association)
        end

        def follow_associations(association_names)
          association_names.inject(self) { |klass, name| klass&.reflect_on_association(name)&.klass }
        end

        def follow_associations_with_virtual(association_names)
          association_names.inject(self) { |klass, name| klass&.reflection_with_virtual(name)&.klass }
        end

        # invalid associations return a nil
        # real reflections are followed
        # a virtual association will stop the traversal
        # @returns [nil, Array<Relation>]
        def collect_reflections(association_names)
          klass = self
          association_names.each_with_object([]) do |name, ret|
            reflection = klass.reflect_on_association(name)
            if reflection.nil?
              if klass.reflection_with_virtual(name)
                break(ret)
              else
                break
              end
            end
            klass = reflection.klass
            ret << reflection
          end
        end

        def collect_reflections_with_virtual(association_names)
          klass = self
          association_names.collect do |name|
            reflection = klass.reflection_with_virtual(name) || break
            klass = reflection.klass
            reflection
          end
        end

        private

        def add_virtual_reflection(reflection, name, uses, _options)
          raise ArgumentError, "macro must be specified" unless reflection

          reset_virtual_reflection_information
          _virtual_reflections[name.to_sym] = reflection
          define_virtual_include(name.to_s, uses)
        end

        def reset_virtual_reflection_information
        end

        def _virtual_reflections
          @virtual_reflections ||= {}
        end
      end
    end
  end
end
