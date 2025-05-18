require "sinatra/base"
require "sinatra/json"
require 'html2slim'
require 'tempfile'
require 'slim'

class SlimConverter < Sinatra::Base
  before do
    # Allow requests from tools.gizipp.com
    headers['Access-Control-Allow-Origin'] = 'https://tools.gizipp.com'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin, content-type'
  end

  options '*' do
    response.headers['Allow'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
  end

  get '/' do
    json status: :ok
  end

  post '/convert' do
    temp_file = Tempfile.new(['input', '.erb'])
    begin
      temp_file.write(params[:raw_text])
      temp_file.rewind
      json converted_text: HTML2Slim.convert!(temp_file, 'erb').to_s
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  post '/convert-to-html' do
    begin
      # Validate input
      if params[:raw_slim].nil? || params[:raw_slim].empty?
        status 400
        return json error: "Raw slim is required"
      end

      # Ensure proper encoding
      input_text = params[:raw_slim].force_encoding('UTF-8')
      
      # Convert Slim to HTML using Slim::Template
      html = Slim::Template.new { input_text }.render
      json converted_text: html
    rescue => e
      status 400
      json error: e.message
    end
  end
end
