defmodule Loggerinner.CLI do
  use Hound.Helpers

  def main(_args) do
    log_in(
      System.get_env("STAFF_ID"),
      System.get_env("PASSWORD"),
      IO.gets("Passcode: ")
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

    Hound.start_session(browser: :chrome, user_agent: :chrome_desktop)

    navigate_to("https://wgdc.exconnect.hsbc.co.uk/logon/LogonPoint/tmindex.html")

    login_field = find_element(:name, "login")
    password_field = find_element(:name, "passwd1")
    passcode_field = find_element(:name, "passwd")

    fill_field(login_field, username)
    fill_field(password_field, password)
    fill_field(passcode_field, passcode)

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
    System.cmd("gio", ["open", latest_file])
  end
end
