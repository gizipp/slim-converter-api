require "sinatra/base"
require "sinatra/json"
require 'html2slim'
require 'html2slim/converter'
require 'tempfile'
require 'slim'
require 'slim/erb_converter'

class SlimConverter < Sinatra::Base
  configure :test do
    set :protection, except: :http_origin
  end

  before %r{/convert-to-(slim|html|erb|html-erb)} do
    @input_text = validate_input(params[:raw_text], "Raw text is required")
  end

  after do
    set_cors_headers
  end

  options '*' do
    response.headers['Allow'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
  end

  get '/' do
    json status: :ok
  end

  post '/convert-to-slim' do
    begin
      json converted_text: convert_to_slim(@input_text)
    rescue => e
      status 400
      json error: e.message
    end
  end

  post '/convert-to-html' do
    begin
      json converted_text: convert_to_html(@input_text)
    rescue => e
      status 400
      json error: e.message
    end
  end

  post '/convert-to-html-erb' do
    begin
      json converted_text: convert_to_erb(@input_text)
    rescue => e
      status 400
      json error: e.message
    end
  end

  private

  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = 'https://tools.gizipp.com'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin, content-type'
  end

  def validate_input(text, error_message)
    if text.nil? || text.empty?
      halt 400, json(error: error_message)
    end
    text.force_encoding('UTF-8')
  end

  def convert_to_slim(input_text)
    temp_file = Tempfile.new(['input', '.erb'])
    begin
      temp_file.write(input_text)
      temp_file.rewind
      HTML2Slim.convert!(temp_file, 'erb').to_s
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def convert_to_html(input_text)
    Slim::Template.new { input_text }.render
  end

  def convert_to_erb(input_text)
    Slim::ERBConverter.new.call(input_text)
  end
end
