
#### Goal
Write tests to assert `ExScheduler.Worker` periodic behaviour in `test/ex_scheduler/worker_test.exs`.

# ExScheduler

Cron-like job scheduler in few lines of elixir code.  
Inspired in [this answer by José Valim](https://stackoverflow.com/a/32097971).  
Added cron syntax, with extended support for seconds.

## Installation

```elixir
def deps do
  [
    {:ex_scheduler, "~> 0.1.0"}
  ]
end
```

Add ExScheduler.Worker to your supervision tree:
```elixir
  children = [
    {ExScheduler.Worker, jobs}
  ]
```

And the jobs configuration:
```elixir
  defp jobs() do
    [
      %{cron: "* * * * * *", module: Example, function: :hello, args: ["world"]},
      %{cron: "* * * * * *", module: PerformExample},
    ]
  end
```

If using Phoenix Framework, you should pull this configuration from config.exs.

#### Important:
- When the function is omitted, `perform/0` function is called.
- When `args` are ommited, the function is called with no attributes.
- Cron expressions are evaluated over UTC time.

## Testing

Attempting to test  `Task` execution across process boundaries is ultimately a problem of observability. Specifically, the usage of `Task.Supervisor` severs the relationship between the process and the caller leaving no way for the caller to be explicitly aware of `Task` activity.

Fortunately, `Process.get("$callers")`  returns a list of callers for the current process, which we then use to determine the PID of the parent process. This information allows us to implement a “spy” in our test cases to verify that `Task` activity is as expected.

During test execution, the spy will emit “regular” process messages to the parent, our `GenServer`, which we’ll intercept with `:erlang.trace/3` and verify with `assert_receive/3`.

Changes to the `ExScheduler.Worker` code are limited to the following:

1. Reimplementation of the default `handle_info/3` as follows:

`def handle_info(_msg, state), do: {:noreply, state}`

(Recall that any present implementation of `handle_info/3` in a `GenServer` will override the included (via `use`)  `handle_info/3` forcing us to reimplement.)

2. Refactor: Extract method for defining the “MFA” Task arguments as `build_task_args/1`.

Let me know if you have any questions. -Chad
