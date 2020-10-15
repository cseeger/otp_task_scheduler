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
    test "mfa uses perform/0 by default" do
      state = %{
        jobs: [%{cron: "* * * * * *", module: Hello}],
        next_job_index: 0
      }

      assert {Hello, :perform, []} = Worker.build_task_args(state)
    end

    test "mfa uses function with 0 arity by default" do
      state = %{
        jobs: [%{cron: "* * * * * *", module: Hello, function: :hello}],
        next_job_index: 0
      }

      assert {Hello, :hello, []} = Worker.build_task_args(state)
    end

    test "mfa uses custom function with args" do
      state = %{
        jobs: [
          %{
            cron: "* * * * * *",
            module: Hello,
            function: :hello,
            args: ["world"]
          }
        ],
        next_job_index: 0
      }

      assert {Hello, :hello, ["world"]} = Worker.build_task_args(state)
    end
  end

  describe "handle_info/2 :work" do
    test "queues Task with perform/0 by default" do
      config = [%{cron: "* * * * * *", module: Hello}]

      {:ok, pid} = GenServer.start_link(Worker, config)
      :erlang.trace(pid, true, [:receive])

      Process.sleep(1050)

      assert_receive {
        :trace,
        ^pid,
        :receive,
        {:task_args, {Hello, :perform}}
      }
    end

    test "queues Task function with 0 arity by default" do
      config = [%{cron: "* * * * * *", module: Hello, function: :hello}]

      {:ok, pid} = GenServer.start_link(Worker, config)
      :erlang.trace(pid, true, [:receive])

      Process.sleep(1050)

      assert_receive {
        :trace,
        ^pid,
        :receive,
        {:task_args, {Hello, :hello, []}}
      }
    end

    test "queues Task uses custom function with args" do
      config = [
        %{cron: "* * * * * *", module: Hello, function: :hello, args: ["test"]}
      ]

      {:ok, pid} = GenServer.start_link(Worker, config)
      :erlang.trace(pid, true, [:receive])

      Process.sleep(1050)

      assert_receive {
        :trace,
        ^pid,
        :receive,
        {:task_args, {Hello, :hello, ["test"]}}
      }
    end
  end
end
