defmodule Loggerinner.CLI do
  use Hound.Helpers

  def main(_args) do
    log_in(
      System.get_env("STAFF_ID"),
      System.get_env("PASSWORD"),
      IO.gets("Passcode: ")
    )
  end

  def log_in(username, password, passcode) do
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
    # Hound.end_session()
  end
end
