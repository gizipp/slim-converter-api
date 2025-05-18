require "sinatra/base"
require "sinatra/json"
require 'html2slim'
require 'tempfile'

class SlimConverter < Sinatra::Base
  before do
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin'
  end

  options '*' do
    response.headers['Allow'] = 'HEAD,GET,PUT,DELETE,OPTIONS,POST'
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
end
