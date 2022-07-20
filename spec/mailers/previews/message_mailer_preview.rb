# Preview all emails at http://localhost:3000/rails/mailers/order_mailer
class MessageMailerPreview < ActionMailer::Preview
  def default_response
    message = Message.new(name: 'Daniel', email: 'daniel.enm17@gmail.com', phone: '5521529085',
                          subject: 'Hello, this is subject', organization_name: '',
                          organization_website: '', organization_ein: '', content: 'Hello, this is content')

    MessageMailer.default_response(message)
  end
end
