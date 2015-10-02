class Mailers::ForgotPassword
  include Lotus::Mailer

  from    '<from>'
  to      '<to>'
  subject 'Hello'
end
