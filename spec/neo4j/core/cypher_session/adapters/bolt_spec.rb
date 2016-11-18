require 'spec_helper'
require 'neo4j/core/cypher_session/adapters/bolt'
require './spec/neo4j/core/shared_examples/adapter'

describe Neo4j::Core::CypherSession::Adapters::Bolt, bolt: true do
  let(:adapter_class) { Neo4j::Core::CypherSession::Adapters::Bolt }
  let(:url) { ENV['NEO4J_BOLT_URL'] }

  # let(:adapter) { adapter_class.new(url, logger_level: Logger::DEBUG) }
  let(:adapter) { adapter_class.new(url) }

  subject { adapter }

  describe '#initialize' do
    before do
      allow_any_instance_of(adapter_class).to receive(:open_socket)
    end

    let_context(url: 'url') { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: :symbol) { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: 123) { subject_should_raise ArgumentError, /Invalid URL/ }

    let_context(url: 'http://localhost:7687') { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: 'http://foo:bar@localhost:7687') { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: 'https://localhost:7687') { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: 'https://foo:bar@localhost:7687') { subject_should_raise ArgumentError, /Invalid URL/ }

    let_context(url: 'bolt://foo@localhost:') { subject_should_not_raise }
    let_context(url: 'bolt://:foo@localhost:7687') { subject_should_not_raise }

    let_context(url: 'bolt://localhost:7687') { subject_should_not_raise }
    let_context(url: 'bolt://foo:bar@localhost:7687') { subject_should_not_raise }
  end

  context 'connected adapter' do
    before { adapter.connect }

    it_behaves_like 'Neo4j::Core::CypherSession::Adapter'
  end
end
