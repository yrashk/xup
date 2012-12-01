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
    worker id: TestSrv
  end
  worker(arg) do
    [id: SomeSrv, start_func: {TestSrv, :start_link, [arg]}]
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
  end

  test "actual start" do
    TestSup.start_link
  end

end
