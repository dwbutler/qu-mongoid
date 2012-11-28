require 'spec_helper'
require 'qu-mongoid'

describe Qu::Backend::Mongoid do
  it_should_behave_like 'a backend'

  describe 'connection' do
    it 'should use a separate connection in each thread' do
      backend = subject
      connection = subject.connection
      separate_connection = false
      Thread.new do
        separate_connection = (backend.connection != connection)
      end.join
      separate_connection.should be_true
    end
    
    it 'should default to the qu database' do
      subject.connection.should be_instance_of(Moped::Session)
      subject.connection.options[:database].should == 'qu'
    end
    
    it 'should default to the :default session' do
      subject.session.should == :default
      subject.connection.should == ::Mongoid::Sessions.with_name(subject.session)
    end
    
    it 'should have a configurable session that works with threads' do
      subject.connection = nil
      
      ::Mongoid.sessions[:qu] = {:uri => 'mongodb://127.0.0.1:27017/quspec', :max_retries_on_connection_failure => 4}
      Qu.backend = subject
      Qu.configure do |c|
        c.backend.session = :qu
      end
      subject.connection.should == ::Mongoid::Sessions.with_name(:qu)
      
      should_have_qu_session_in_new_thread = false
      Thread.new do
        should_have_qu_session_in_new_thread = (subject.connection == ::Mongoid::Sessions.with_name(:qu))
      end.join
      should_have_qu_session_in_new_thread.should be_true
      
      # Clean up
      subject.connection=nil
      ::Mongoid.connect_to('qu')
    end
    
    it 'should use MONGOHQ_URL from heroku' do
      # Clean up from other tests
      ::Mongoid.sessions[:default]  = nil
      subject.connection=nil
      ::Mongoid::Sessions.clear
      
      ENV['MONGOHQ_URL'] = 'mongodb://127.0.0.1:27017/quspec'
      subject.connection.options[:database].should == 'quspec'
      subject.connection.cluster.nodes.first.resolved_address.should == "127.0.0.1:27017"
      ::Mongoid.sessions[:default][:hosts].should include("127.0.0.1:27017")
      
      # Clean up MONGOHQ stuff
      ENV.delete('MONGOHQ_URL')
      subject.connection=nil
      ::Mongoid.connect_to('qu')
    end
  end

  describe 'reserve' do
    let(:worker) { Qu::Worker.new }

    describe "on mongo >=2" do
      it 'should return nil when no jobs exist' do
        subject.clear
        Moped::Session.any_instance.should_receive(:command).and_return(nil)
        lambda { subject.reserve(worker, :block => false).should be_nil }.should_not raise_error
      end
    end

    describe 'on mongo <2' do
      it 'should return nil when no jobs exist' do
        subject.clear
        subject.connection.should_receive(:command).and_raise(Moped::Errors::OperationFailure.new(nil, 'test'))
        lambda { subject.reserve(worker, :block => false).should be_nil }.should_not raise_error
      end
    end
  end
end
