require 'spec_helper'
require 'qu-mongoid'

describe Qu::Backend::Mongoid do
  it_should_behave_like 'a backend'

  describe 'connection' do
    it 'uses a separate connection in each thread' do
      backend = subject
      connection = subject.connection
      separate_connection = false
      Thread.new do
        separate_connection = (backend.connection != connection)
      end.join
      expect(separate_connection).to be true
    end
    
    it 'defaults to the qu database' do
      expect(subject.connection).to be_instance_of(Moped::Session)
      expect(subject.connection.options[:database]).to eq('qu')
    end
    
    it 'defaults to the :default session' do
      expect(subject.session).to eq(:default)
      expect(subject.connection).to eq(::Mongoid::Sessions.with_name(subject.session))
    end
    
    it 'has a configurable session that works with threads' do
      subject.connection = nil
      
      ::Mongoid.sessions[:qu] = {:uri => 'mongodb://127.0.0.1:27017/quspec', :max_retries_on_connection_failure => 4}
      Qu.backend = subject
      Qu.configure do |c|
        c.backend.session = :qu
      end
      expect(subject.connection).to eq(::Mongoid::Sessions.with_name(:qu))
      
      should_have_qu_session_in_new_thread = false
      Thread.new do
        should_have_qu_session_in_new_thread = (subject.connection == ::Mongoid::Sessions.with_name(:qu))
      end.join
      expect(should_have_qu_session_in_new_thread).to be true
      
      # Clean up
      subject.connection=nil
      ::Mongoid.connect_to('qu')
    end
    
    it 'uses MONGOHQ_URL from heroku' do
      # Clean up from other tests
      ::Mongoid.sessions[:default]  = nil
      subject.connection = nil
      ::Mongoid::Sessions.clear
      
      ENV['MONGOHQ_URL'] = 'mongodb://127.0.0.1:27017/quspec'
      expect(subject.connection.options[:database]).to eq('quspec')

      node = subject.connection.cluster.nodes.first
      resolved_address = if node.respond_to?(:resolved_address)
                           node.resolved_address
                         else
                           node.address.resolved
                         end

      expect(resolved_address).to eq("127.0.0.1:27017")

      expect(::Mongoid.sessions[:default][:hosts]).to include("127.0.0.1:27017")
      
      # Clean up MONGOHQ stuff
      ENV.delete('MONGOHQ_URL')
      subject.connection=nil
      ::Mongoid.connect_to('qu')
    end
  end

  describe 'reserve' do
    let(:worker) { Qu::Worker.new }

    describe "on mongo >=2" do
      it 'returns nil when no jobs exist' do
        subject.clear
        expect_any_instance_of(Moped::Session).to receive(:command).and_return(nil)
        expect { expect(subject.reserve(worker, :block => false)).to be_nil }.not_to raise_error
      end
    end

    describe 'on mongo <2' do
      it 'returns nil when no jobs exist' do
        subject.clear
        expect(subject.connection).to receive(:command).and_raise(Moped::Errors::OperationFailure.new(nil, 'test'))
        expect { expect(subject.reserve(worker, :block => false)).to be_nil }.not_to raise_error
      end
    end
  end
end
