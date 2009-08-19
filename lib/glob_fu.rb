module GlobFu
  class << self
    def find(*args, &block)
      options = (Hash === args.last) ? args.pop : {}
      args = args.first if Array === args.first

      results = do_find(args, options)

      if block
        results.each(&block)
      end
      results
    end

    private

    def do_find(args, options)
      if [:root, :suffix].any? { |k| options[k] }
        args = args.dup
      end

      if options[:root]
        args.collect! { |a| File.join(options[:root], a) }
      end

      if options[:suffix]
        args.collect! { |a| "#{a}.*" }
      end

      ret = args.inject([]) { |r,a| r.concat(do_single_find(a, options)) }
      ret.uniq!
      ret
    end

    def do_single_find(path, options)
      ret = Dir[path]

      if options[:suffix]
        n_dots = File.basename(path).count('.')
        basename_regex = (['[^\.]+'] * n_dots).join('\.')

        suffix_regex = ""
        if options[:extra_suffix]
          suffix_regex << "\.#{Regexp.quote(options[:extra_suffix])}"
        end
        suffix_regex << "\.#{Regexp.quote(options[:suffix])}"
        if options[:optional_suffix]
          suffix_regex << "(\.#{Regexp.quote(options[:optional_suffix])})?"
        end

        regex = %r{(/|^)#{basename_regex}#{suffix_regex}$}
        ret.reject! { |f| !(f =~ regex) }
        if options[:optional_suffix]
          ret.reject! { |f| f =~ /\.#{Regexp.quote(options[:suffix])}$/ && File.exist?("#{f}.#{options[:optional_suffix]}") }
        end
      end

      ret.sort!

      ret
    end
  end
end
