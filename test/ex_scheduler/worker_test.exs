defmodule ExScheduler.WorkerTest do
  use ExUnit.Case
  alias ExScheduler.Worker

  defmodule Hello do
    def perform() do
      ref = Enum.at(Process.get(:"$callers"), 0)
      send(ref, {:task_args, {Hello, :perform}})
    end

    def hello() do
      ref = Enum.at(Process.get(:"$callers"), 0)
      send(ref, {:task_args, {Hello, :hello, []}})
    end

    def hello(name) do
      ref = Enum.at(Process.get(:"$callers"), 0)
      send(ref, {:task_args, {Hello, :hello, [name]}})
    end
  end

  describe "build_task_args/1" do
    setup context do
      state = %{
        jobs: context[:jobs],
        next_job_index: 0
      }

      {:ok, state: state}
    end

    @tag jobs: [%{cron: "* * * * * *", module: Hello}]
    test "mfa uses perform/0 by default", %{state: state} do
      assert {Hello, :perform, []} = Worker.build_task_args(state)
    end

    @tag jobs: [%{cron: "* * * * * *", module: Hello, function: :hello}]
    test "mfa uses function with 0 arity by default", %{state: state} do
      assert {Hello, :hello, []} = Worker.build_task_args(state)
    end

    @tag jobs: [
           %{
             cron: "* * * * * *",
             module: Hello,
             function: :hello,
             args: ["world"]
           }
         ]
    test "mfa uses custom function with args", %{state: state} do
      assert {Hello, :hello, ["world"]} = Worker.build_task_args(state)
    end
  end

  describe "handle_info/2 :work" do
    setup context do
      config = context[:config]

      {:ok, pid} = GenServer.start_link(Worker, config)
      :erlang.trace(pid, true, [:receive])

      Process.sleep(1050)

      {:ok, pid: pid}
    end

    @tag config: [%{cron: "* * * * * *", module: Hello}]
    test "queues Task with perform/0 by default", %{pid: pid} do
      assert_receive {
        :trace,
        ^pid,
        :receive,
        {:task_args, {Hello, :perform}}
      }
    end

    @tag config: [%{cron: "* * * * * *", module: Hello, function: :hello}]
    test "queues Task function with 0 arity by default", %{pid: pid} do
      assert_receive {
        :trace,
        ^pid,
        :receive,
        {:task_args, {Hello, :hello, []}}
      }
    end

    @tag config: [
           %{
             cron: "* * * * * *",
             module: Hello,
             function: :hello,
             args: ["test"]
           }
         ]
    test "queues Task uses custom function with args", %{pid: pid} do
      assert_receive {
        :trace,
        ^pid,
        :receive,
        {:task_args, {Hello, :hello, ["test"]}}
      }
    end
  end
end
