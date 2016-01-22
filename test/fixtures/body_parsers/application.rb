require 'rexml/document'
require 'hanami/routing/parsing/parser'

class XmlParser < Hanami::Routing::Parsing::Parser
  def mime_types
    ['application/xml', 'text/xml']
  end

  def parse(body)
    result = {}

    xml = ::REXML::Document.new(body)
    xml.elements.each('*') { |el| result[el.name] = el.text }

    result
  end
end

module BodyParsersApp
  class Application < Hanami::Application
    configure do
      body_parsers :json, XmlParser.new

      routes do
        post '/json_parser', to: 'body_parsers#json'
        patch '/xml_parser', to: 'body_parsers#xml'
      end
    end

    load!
  end

  module Controllers::BodyParsers

    class Json
      include BodyParsersApp::Action
      def call(params)
        self.body = params[:success]
      end
    end

    class Xml
      include BodyParsersApp::Action
      def call(params)
        self.body = params[:success]
      end
    end

  end
end
