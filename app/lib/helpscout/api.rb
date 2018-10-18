class Helpscout::API
  MAILBOXES = 'mailboxes'
  CONVERSATIONS = 'conversations'
  TAGS = 'tags'
  FIELDS = 'fields'
  OAUTH2_TOKEN = 'oauth2/token'

  def add_tags(conversation_id, tags)
    call_api(:put, "#{CONVERSATIONS}/#{conversation_id}/#{TAGS}", {
      tags: tags
    })
  end

  def add_custom_fields(conversation_id, dossier_id, browser)
    body = {
      'Dossier ID': dossier_id,
      'Browser': browser
    }.compact.map do |key, value|
      { id: custom_fields[key], value: value }
    end

    call_api(:put, "#{CONVERSATIONS}/#{conversation_id}/#{FIELDS}", { fields: body })
  end

  def create_conversation(email, subject, text, file)
    body = {
      subject: subject,
      customer: customer(email),
      mailboxId: mailbox_id,
      type: 'email',
      status: 'active',
      threads: [
        {
          type: 'customer',
          customer: customer(email),
          text: text,
          attachments: attachments(file)
        }
      ]
    }.compact

    call_api(:post, CONVERSATIONS, body)
  end

  def reports(from, to)
    (from..to)
      .group_by { |date| [date.year, date.month] }
      .keys
      .map { |key| { year: key[0], month: key[1] } }
      .map { |interval| cached_report(interval[:year], interval[:month]) }
  end

  private

  def report(year, month)
    params = {
      start: Time.new(year, month).utc.iso8601,
      end: Time.new(year, month).next_month.utc.iso8601
    }

    Rails.logger.info "[HelpScout API] Retrieving report for #{month}-#{year}…"

    response = call_api(:get, 'reports/company?' + params.to_query)
    if !response.success?
      raise StandardError, "Error while fetching report: #{response.status} '#{response.body}'"
    end

    payload = JSON.parse(response.body)
    payload.dig('current')
  end

  def cached_report(year, month)
    is_current_month = (year == Date.today.year && month == Date.today.month)
    if is_current_month
      raise ArgumentError, 'The report for the current month will change in the future, and cannot be cached.'
    end

    Rails.cache.fetch("helpscout-report-#{year}-#{month}") do
      report(year, month)
    end
  end

  def attachments(file)
    if file.present?
      [
        {
          fileName: file.original_filename,
          mimeType: file.content_type,
          data: Base64.strict_encode64(file.read)
        }
      ]
    else
      []
    end
  end

  def customer(email)
    {
      email: email
    }
  end

  def custom_fields
    @custom_fields ||= get_custom_fields.reduce({}) do |fields, field|
      fields[field[:name].to_sym] = field[:id]
      fields
    end
  end

  def get_custom_fields
    parse_response_body(fetch_custom_fields)[:_embedded][:fields]
  end

  def fetch_custom_fields
    call_api(:get, "#{MAILBOXES}/#{mailbox_id}/#{FIELDS}")
  end

  def call_api(method, path, body = nil)
    url = "#{HELPSCOUT_API_URL}/#{path}"

    case method
    when :get
      Typhoeus.get(url, {
        headers: headers
      })
    when :post
      Typhoeus.post(url, {
        body: body.to_json,
        headers: headers
      })
    when :put
      Typhoeus.put(url, {
        body: body.to_json,
        headers: headers
      })
    end
  end

  def parse_response_body(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  def mailbox_id
    Rails.application.secrets.helpscout[:mailbox_id]
  end

  def headers
    {
      'Authorization': "Bearer #{access_token}",
      'Content-Type': 'application/json; charset=UTF-8'
    }
  end

  def access_token
    @access_token ||= get_access_token
  end

  def get_access_token
    parse_response_body(fetch_access_token)[:access_token]
  end

  def fetch_access_token
    Typhoeus.post("#{HELPSCOUT_API_URL}/#{OAUTH2_TOKEN}", body: {
      grant_type: 'client_credentials',
      client_id: Rails.application.secrets.helpscout[:client_id],
      client_secret: Rails.application.secrets.helpscout[:client_secret]
    })
  end
end
