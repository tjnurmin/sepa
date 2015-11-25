require 'test_helper'

class OpGenericSoapBuilderTest < ActiveSupport::TestCase
  def setup
    @params = op_generic_params

    # Convert the keys here since the conversion is usually done by the client and these tests
    # bypass the client
    @params[:signing_private_key]     = rsa_key @params[:signing_private_key]
    @params[:own_signing_certificate] = x509_certificate @params[:own_signing_certificate]

    @soap_request = Sepa::SoapBuilder.new(@params)
    @doc          = Nokogiri::XML(@soap_request.to_xml)
  end

  def test_receiver_is_is_set_correctly
    receiver_id_node = @doc.xpath('//bxd:ReceiverId', bxd: 'http://model.bxd.fi').first
    assert_equal 'OKOYFIHH', receiver_id_node.content
  end

  test 'validates against schema' do
    errors = []

    Dir.chdir(SCHEMA_PATH) do
      xsd = Nokogiri::XML::Schema(IO.read('soap.xsd'))
      xsd.validate(@doc).each do |error|
        errors << error
      end
    end

    assert errors.empty?, "The following schema validations failed:\n#{errors.join("\n")}"
  end

  test 'validates against ws security schema' do
    wsse = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'

    ws_node = @doc.xpath('//wsse:Security', wsse: wsse)
    ws_node = ws_node.to_xml
    ws_node = Nokogiri::XML(ws_node)

    errors = []

    Dir.chdir(SCHEMA_PATH) do
      xsd = Nokogiri::XML::Schema(IO.read('oasis-200401-wss-wssecurity-secext-1.0.xsd'))
      xsd.validate(ws_node).each do |error|
        errors << error
      end
    end

    assert errors.empty?, "The following schema validations failed:\n#{errors.join("\n")}"
  end
end
