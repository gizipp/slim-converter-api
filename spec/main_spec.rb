ENV['RACK_ENV'] = 'test'
require 'spec_helper'
require 'rack/test'
require_relative '../app/main'

RSpec.describe SlimConverter do
  include Rack::Test::Methods

  def app
    SlimConverter
  end

  describe 'CORS headers' do
    it 'sets CORS headers for all requests' do
      get '/'
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('https://tools.gizipp.com')
      expect(last_response.headers['Access-Control-Allow-Methods']).to eq('GET, POST, OPTIONS')
      expect(last_response.headers['Access-Control-Allow-Headers']).to include('content-type')
    end
  end

  describe 'GET /' do
    it 'returns ok status' do
      get '/'
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)).to eq({ 'status' => 'ok' })
    end
  end

  describe 'POST /convert-to-slim' do
    context 'with valid input' do
      let(:valid_html) { '<div>Hello World</div>' }
      let(:expected_slim) { "div\n  | Hello World\n" }

      it 'converts HTML to Slim' do
        post '/convert-to-slim', { raw_text: valid_html }
        expect(last_response).to be_ok
        expect(JSON.parse(last_response.body)['converted_text'].strip).to eq(expected_slim.strip)
      end

      xit 'converts HTML with ERB to Slim' do
        html_with_erb = <<~HTML
          <html>
            <head>
              <title>Enter Your HTML ERB Code Heree</title>
            </head>
            <body>
              <% foo = [1,2,3] %>
              <%- foo.each do |bar| %>
                <p>Click Convert to test it out!</p>
              <% end %>
            </body>
          </html>
        HTML

        expected_slim = <<~SLIM
          html
            head
              title
                | Enter Your HTML ERB Code Heree
            body
              |  <% foo = [1,2,3] %> <%- foo.each do |bar| %> 
              p
                | Click Convert to test it out!
              |  <% end %> 
        SLIM

        post '/convert-to-slim', { raw_text: html_with_erb }
        expect(last_response).to be_ok
        expect(JSON.parse(last_response.body)['converted_text'].strip).to eq(expected_slim.strip)
      end
    end

    context 'with invalid input' do
      it 'returns 400 for empty input' do
        post '/convert-to-slim', { raw_text: '' }
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['error']).to eq('Raw text is required')
      end

      it 'returns 400 for nil input' do
        post '/convert-to-slim', { raw_text: nil }
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['error']).to eq('Raw text is required')
      end
    end
  end

  describe 'POST /convert-to-html' do
    context 'with valid input' do
      let(:valid_slim) { "div\n  | Hello World\n" }
      let(:expected_html) { "<div>Hello World</div>" }

      it 'converts Slim to HTML' do
        post '/convert-to-html', { raw_text: valid_slim }
        expect(last_response).to be_ok
        expect(JSON.parse(last_response.body)['converted_text']).to eq(expected_html)
      end
    end

    context 'with invalid input' do
      it 'returns 400 for empty input' do
        post '/convert-to-html', { raw_text: '' }
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['error']).to eq('Raw text is required')
      end

      it 'returns 400 for nil input' do
        post '/convert-to-html', { raw_text: nil }
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['error']).to eq('Raw text is required')
      end
    end
  end

  describe 'POST /convert-to-html-erb' do
    context 'with valid input' do
      let(:valid_slim) { "div\n  - if true\n    h1 | Hello\n  - else\n    p | No content" }
      let(:expected_erb) { "<div>\n<% if true\n %><h1>| Hello</h1>\n<% else\n %><p>| No content</p>\n<% end %></div>" }

      it 'converts Slim to ERB' do
        post '/convert-to-html-erb', { raw_text: valid_slim }
        expect(last_response).to be_ok
        expect(JSON.parse(last_response.body)['converted_text']).to eq(expected_erb)
      end
    end

    context 'with invalid input' do
      it 'returns 400 for empty input' do
        post '/convert-to-html-erb', { raw_text: '' }
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['error']).to eq('Raw text is required')
      end

      it 'returns 400 for nil input' do
        post '/convert-to-html-erb', { raw_text: nil }
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['error']).to eq('Raw text is required')
      end
    end
  end
end 