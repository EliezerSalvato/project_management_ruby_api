user = User.find_or_create_by!(email: "user@example.com") do |new_user|
  new_user.first_name = "User"
  new_user.last_name = "Example"
  new_user.password = "12345678"
  new_user.verified = true
end

first_date = Date.new(2026, 1, 1)
last_date = Date.new(2027, 12, 31)

1.upto(100) do |number|
  user.projects.find_or_create_by!(name: format("Projeto %02d", number)) do |project|
    start_date = rand(first_date...last_date)

    project.client_name = "Clicksign"
    project.start_date = start_date
    project.end_date = rand(start_date.next_day..last_date)
  end
end
