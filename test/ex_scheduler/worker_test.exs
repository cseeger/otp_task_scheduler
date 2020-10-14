defmodule ExScheduler.WorkerTest do
  use ExUnit.Case
  alias ExScheduler.Worker

  defmodule Hello do
    def perform(), do: nil
    def hello(), do: nil
    def hello(_name), do: nil
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

  test "queues Task with args" do
    config = [
      %{cron: "* * * * * *", module: Hello, function: :hello, args: ["test"]}
    ]

    {:ok, pid} = GenServer.start_link(Worker, config)
    :erlang.trace(pid, true, [:receive])

    Process.sleep(1050)

    # assert handle_info(:work)
    assert_receive {:trace, ^pid, :receive, :work}

    # assumes the task_pid is the PID for Task
    assert_receive {:trace, ^pid, :receive, {_, {:ok, task_pid}}}
    assert task_pid != nil

    # assert callback to Worker was successful
    assert_receive {
      :trace,
      ^pid,
      :receive,
      {:task_args, {Hello, :hello, ["test"]}}
    }
  end
end
