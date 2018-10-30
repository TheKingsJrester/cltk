module EXP_LANG
  class EXP_LANG::Undefined; end
  class Scope(T)
    property :parent
    getter :dict

    def initialize(@parent : Scope(T)? = nil, @dict = {} of String => T)
    end

    def eval(exp)
      exp.eval_scope(self)
    end

    def get(key)
      p = parent
      if @dict.fetch(key, nil)
        @dict[key]
      elsif p
        p.get(key)
      else
        EXP_LANG::Undefined
      end
    end

    def [](key)
      get(key)
    end

    def set(key, value)
      @dict[key] = value
      value
    end

    def []=(key, value)
      set(key, value)
    end

    def delete(key)
      @dict.delete key
    end

    def has?(key)
      @dict[key]?
    end

    def []?(key)
      has?(key)
    end

    def inherit
      EXP_LANG::Scope(T).new(self)
    end

    def clone
      EXP_LANG::Scope(T).new(nil, @dict.clone)
    end
  end
end
