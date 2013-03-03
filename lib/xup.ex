defrecord Xup.Worker, id: nil, start_func: nil, restart: :permanent, shutdown: 5000,
                      type: :worker, modules: nil do
  defoverridable new: 1

  def new(options) do
    if is_atom(options[:id]) and nil?(options[:start_func]) do
      options = Keyword.put(options, :start_func, {options[:id], :start_link, []})
    end
    if not nil?(options[:start_func]) and nil?(options[:modules]) do
      {module, _, _} = options[:start_func]
      options = Keyword.put(options, :modules, [module])
    else
      options = Keyword.put(options, :modules, :dynamic)
    end
    if not nil?(options[:module]) do
      {_, function, args} = options[:start_func]
      options = Keyword.put(options, :start_func, {options[:module], function, args})
    end
    if not nil?(options[:function]) do
      {module, _, args} = options[:start_func]
      options = Keyword.put(options, :start_func, {module, options[:function], args})
    end
    if not nil?(options[:args]) do
      {module, function, _} = options[:start_func]
      options = Keyword.put(options, :start_func, {module, function, options[:args]})
    end
    super(options)
  end
  def to_spec(r) do
    list_to_tuple(tl(tuple_to_list(r)))
  end
end

defmodule Xup do
  defmacro __using__(options) do
    {max_r, max_t} = options[:max_restarts] || {1, 1}
    quote do
      @behaviour :supervisor

      def start_link do
        start_link([])
      end

      if unquote(options[:name]) == false do
        def start_link(arg) do
          :supervisor.start_link(__MODULE__, arg)
        end
      else
        def start_link(arg) do
          :supervisor.start_link(unquote(options[:name]) || {:local, unquote(options[:local]) || __MODULE__}, __MODULE__, arg)
        end
      end

      defoverridable start_link: 0
      defoverridable start_link: 1

      def init(arg) do
        {:ok, {{unquote(options[:strategy]) || :one_for_one,
                unquote(max_r), unquote(max_t)}, children(arg)}}
      end

      import Xup

      Module.register_attribute __MODULE__, :children, persist: false, accumulate: true

      @before_compile Xup

    end
  end

  defmacro defsupervisor(name, options // []) do
    __defsupervisor__(name, options)
  end

  defmacro defsupervisor(name, options, [do: block]) do
    __defsupervisor__(name, Keyword.merge(options, do: block))
  end

  defp __defsupervisor__(name, options) do
    block = options[:do]
    options = Keyword.delete options, :do
    quote do
      defmodule unquote(name) do
        use Xup, unquote(options)
        unquote(block)
      end
    end
  end

  defmacro supervisor(name, opts) do
    __supervisor__(name, opts)
  end

  defmacro supervisor(name, opts, [do: block]) do
    __supervisor__(name, Keyword.merge(opts, [do: block]))
  end

  defp __supervisor__(name, opts) do
    quote do
      defsupervisor unquote(name), unquote(opts)
      worker id: unquote(name), type: :supervisor
    end
  end

  defmacro worker([do: block]) do
    __worker__(quote(do: _arg), [do: block])
  end

  defmacro worker(config) do
    __worker__(quote(do: _arg), [do: config])
  end

  defmacro worker(argument, [do: block]) do
    __worker__(argument, [do: block])
  end

  defp __worker__(argument, [do: block]) do
    quote do
      @children unquote(:erlang.phash2(block))
      defp child(unquote(:erlang.phash2(block)), unquote(argument)) do
        case unquote(block) do
          nil -> nil
          v -> Xup.Worker.new(v).to_spec
        end
      end
    end
  end

  defmacro __before_compile__(_) do
    quote do
      defp children(arg) do
        Enum.filter(lc c inlist Enum.reverse(@children) do
                      child(c, arg)
                    end, fn(c) -> not nil?(c) end)
      end
    end
  end

end
