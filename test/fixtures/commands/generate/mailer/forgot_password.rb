class Mailers::ForgotPassword
  include Hanami::Mailer

  from    '<from>'
  to      '<to>'
  subject 'Hello'
end
