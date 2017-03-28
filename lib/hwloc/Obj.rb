module Hwloc

  ObjType = enum( :obj_type, [
    :OBJ_SYSTEM,
    :OBJ_MACHINE,
    :OBJ_NUMANODE,
    :OBJ_PACKAGE,
    :OBJ_CACHE,
    :OBJ_CORE,
    :OBJ_PU,
    :OBJ_GROUP,
    :OBJ_MISC,
    :OBJ_BRIDGE,
    :OBJ_PCI_DEVICE,
    :OBJ_OS_DEVICE,
    :OBJ_TYPE_MAX
  ] )

  attach_function :hwloc_compare_types, [:obj_type, :obj_type], :int

  def self.compare_types(type1, type2)
    return Hwloc.hwloc_compare_types(type1, type2)
  end

  ObjCacheType = enum( :obj_cache_type, [
    :OBJ_CACHE_UNIFIED,
    :OBJ_CACHE_DATA,
    :OBJ_CACHE_INSTRUCTION
  ] )

  ObjOsdevType = enum( :obj_osdev_type, [
    :OBJ_OSDEV_BLOCK,
    :OBJ_OSDEV_GPU,
    :OBJ_OSDEV_NETWORK,
    :OBJ_OSDEV_OPENFABRICS,
    :OBJ_OSDEV_DMA,
    :OBJ_OSDEV_COPROC
  ] )

  class Distances < FFI::Struct
    layout :relative_depth, :uint,
           :nbobjs,         :uint,
           :latency,        :pointer,
           :latency_max,    :float,
           :latency_base,   :float
  end

  class ObjInfo < FFI::Struct
    layout :name, :string,
           :value, :string

    def to_s
      return "#{self[:name]}:#{self[:value]}"
    end

  end

  class ObjMemoryPageType < FFI::Struct
    layout :size,  :uint64,
           :count, :uint64
  end

  class ObjMemory < FFI::Struct
    layout :total_memory, :uint64,
           :local_memory, :uint64,
           :page_types_len, :uint,
           :page_types, :pointer
  end

  class Obj < FFI::Struct
  end

  class Obj
    layout_array = [
      :type,             :obj_type,
      :os_index,         :uint,
      :name,             :string,
      :memory,           ObjMemory,
      :attr,             :pointer,
      :depth,            :uint,
      :logical_index,    :uint,
      :os_level,         :int,
      :next_cousin,      Obj.ptr,
      :prev_cousin,      Obj.ptr,
      :parent,           Obj.ptr,
      :sibling_rank,     :uint,
      :next_sibling,     Obj.ptr,
      :prev_sibling,     Obj.ptr,
      :arity,            :uint,
      :children,         :pointer,
      :first_child,      Obj.ptr,
      :last_child,       Obj.ptr,
      :user_data,        :pointer,
      :cpuset,           :cpuset,
      :complete_cpuset,  :cpuset,
      :online_cpuset,    :cpuset,
      :allowed_cpuset,   :cpuset,
      :nodeset,          :nodeset,
      :complete_nodeset, :nodeset,
      :allowed_nodeset,  :nodeset,
      :distances,        :pointer,
      :distances_count,  :uint,
      :infos,            :pointer,
      :infos_count,      :uint,
      :symmetric_subtree,:int
    ]

    layout *layout_array

    def method_missing(m, *args, &block)
      begin
        return self[m]
      rescue
        super
      end
    end

    layout_array.each_slice(2) { |f|
      case f[1]
      when :cpuset
        define_method(f[0]) {
          p = self[f[0]]
          return nil if p.null?
          return Cpuset::new(p)
        }
      when :nodeset
        define_method(f[0]) {
          p = self[f[0]]
          return nil if p.null?
          return Nodeset::new(p)
        }
      when Obj.ptr
        define_method(f[0]) {
          p = self[f[0]]
          return nil if p.to_ptr.null?
          return p
        }
      end
    }

    def children
      arity = self[:arity]
      if arity == 0 then
        return []
      else
        return self[:children].read_array_of_pointer(arity).collect { |p| Obj::new(p) }
      end
    end

    def distances
      distances_count = self[:distances_count]
      if distances_count == 0 then
        return []
      else
        return self[:distances].read_array_of_pointer(distances_count).collect { |p| Distances::new(p) }
      end
    end

    def infos
      infos_count = self[:infos_count]
      if infos_count == 0 then
        return []
      else
        return infos_count.times.collect { |i| ObjInfo::new(self[:infos] + i*ObjInfo.size) }
      end
    end

  end

end
