defrecord Xup.Worker, id: nil, start_func: nil, restart: :permanent, shutdown: 5000,
                      type: :worker, modules: nil do
  defoverridable new: 1

  def new(options) do
    if is_atom(options[:id]) and nil?(options[:start_func]) do
      options = Keyword.put(options, :start_func, {options[:id], :start_link, []})
    end
    if is_atom(options[:id]) and nil?(options[:modules]) do
      options = Keyword.put(options, :modules, [options[:id]])
    end
    if nil?(options[:modules]) do
      options = Keyword.put(options, :modules, :dynamic)
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

      defp children(_), do: children
      defp children, do: []
      defoverridable children: 0, children: 1

      import Xup
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

  def worker(options) when is_list(options) do
    Xup.Worker.new(options).to_spec
  end
  def worker(mod, options // []) when is_atom(mod) do
    worker(Keyword.merge(options, id: mod))
  end
  def supervisor(mod, options // []) when is_atom(mod) do
    worker(Keyword.merge(options, id: mod, type: :supervisor))
  end
  
end