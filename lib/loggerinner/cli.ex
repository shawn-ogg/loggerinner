defmodule Loggerinner.CLI do
  use Hound.Helpers

  def main(_args) do
    log_in(
      System.get_env("STAFF_ID"),
      System.get_env("PASSWORD"),
      System.get_env("PASSCODE")
    )
  end

  def latest_ica() do
    downloads = "#{System.get_env("HOME")}/Downloads"

    [{path, _} | _] =
      Path.wildcard("#{downloads}/*.ica")
      |> Enum.map(&{&1, File.stat!(&1).ctime})
      |> Enum.sort(fn {_, a}, {_, b} -> a >= b end)

    path
  end

  def log_in(username, password, passcode) do
    initial_ica = latest_ica()
    ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36"

    Hound.start_session(browser: :chrome, user_agent: ua)

    navigate_to("https://exconnect.hsbc.co.uk/logon/LogonPoint/tmindex.html")

    login_field = find_element(:name, "login")
    password_field = find_element(:name, "passwd1")
    passcode_field = find_element(:name, "passwd")

    fill_field(login_field, username)
    fill_field(password_field, password)
    fill_field(passcode_field, passcode)

    login_link = find_element(:class, "forms-authentication-button")
    click(login_link)

    download_link = find_element(:class, "storeapp-details-link")
    click(download_link)

    latest_file =
      Enum.reduce_while(1..10, "", fn n, acc ->
        case {n, initial_ica, latest_ica()} do
          {n, same, same} ->
            IO.puts("Waiting for download to complete #{n}")
            :timer.sleep(1000)
            {:cont, acc}

          {_, _initial, latest} ->
            IO.puts("Download complete!")
            {:halt, latest}
        end
      end)

    Hound.end_session()

    IO.puts("opening #{latest_file}")
    _ = spawn(System, :cmd, ["gio", ["open", latest_file]])
    :timer.sleep(100)  # leave enough time to spawn process
  end
end
