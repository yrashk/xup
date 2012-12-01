Code.require_file "../test_helper.exs", __FILE__

import Xup

defmodule TestSrv do
  use GenServer.Behaviour

  def start_link do
    :gen_server.start_link __MODULE__, nil, []
  end

  def start_link(_) do
    :gen_server.start_link __MODULE__, nil, []
  end

end

defsupervisor TestSup, strategy: :one_for_one do

  worker id: TestSrv, restart: :transient
  supervisor TestAnotherSup do
    worker do: [id: TestSrv]
  end
  worker(arg) do
    [id: SomeSrv, start_func: {TestSrv, :start_link, [arg]}]
  end
  worker(arg) do
    case arg do
      true  -> [id: SomeSrv, start_func: {TestSrv, :start_link, [arg]}]
      _ -> nil
    end
  end

end

defmodule XupWorkerTest do
  use ExUnit.Case

  test "start_func guessing" do
    assert Xup.Worker.new(id: Name).start_func == {Name, :start_link, []}
    assert Xup.Worker.new(id: Name, start_func: {MyName, :start_link, []}).start_func == {MyName, :start_link, []}
    assert Xup.Worker.new(id: 1).start_func == nil
  end

  test "modules guessing" do
    assert Xup.Worker.new(id: Name).modules == [Name]
    assert Xup.Worker.new(id: Name, modules: :dynamic).modules == :dynamic
    assert Xup.Worker.new(id: 1).modules == :dynamic
    assert Xup.Worker.new(id: SomeSrv, start_func: {TestSrv, :start_link, []}).modules == [TestSrv]
  end

  test "actual start" do
    {:ok, pid} = TestSup.start_link
    assert [c1,c2,c3] = :supervisor.which_children(pid)
    assert {TestSrv, _, :worker, [TestSrv]} = c1
    assert {TestSup.TestAnotherSup, _, :supervisor, [TestSup.TestAnotherSup]} = c2
    assert {SomeSrv, _, :worker, [TestSrv]} = c3
  end

end
