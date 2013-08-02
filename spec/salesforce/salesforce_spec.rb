require 'spec_helper'

include StsSalesforce

describe RecordIdMatcher do
  class TestId
    def Id
      'TestId'
    end
  end

  it "should make a simple match" do
    sf = mock('Salesforce')
    sobject = mock('SalesforceObject')

    sf.should_receive(:[]).with('Object').and_return(sobject)
    sobject.should_receive(:where).with(Name: 'TestName').and_return(TestId.new)

    matcher = RecordIdMatcher.new(sf, 'Object', Name: 'TestName')
    matcher.call({}).should eq 'TestId'
  end

  it "should try multiple match criteria" do
    sf = mock('Salesforce')
    sobject = mock('SalesforceObject')

    sf.should_receive(:[]).any_number_of_times.with('Object').and_return(sobject)
    sobject.should_receive(:where).with(Name: 'TestName')
    sobject.should_receive(:where).with(Id: 'TestId').and_return(TestId.new)

    matcher = RecordIdMatcher.new(sf, 'Object', [{Name: 'TestName'}, {Id: 'TestId'}])
    matcher.call({}).should eq 'TestId'
  end

  it "should match compound criteria" do
    sf = mock('Salesforce')
    sobject = mock('SalesforceObject')

    sf.should_receive(:[]).any_number_of_times.with('Object').and_return(sobject)
    sobject.should_receive(:where).with({Name: 'TestName', Id: 'TestId'}).and_return(TestId.new)

    matcher = RecordIdMatcher.new(sf, 'Object', {Name: 'TestName', Id: 'TestId'})
    matcher.call({}).should eq 'TestId'
  end

  it "should match a mix of and simple compound criteria" do
    sf = mock('Salesforce')
    sobject = mock('SalesforceObject')

    sf.should_receive(:[]).any_number_of_times.with('Object').and_return(sobject)
    sobject.should_receive(:where).with({Name: 'TestName', Id: 'TestId'})
    sobject.should_receive(:where).with(Type: 'TestType')
    sobject.should_receive(:where).with({Color: 'Blue', Shape: 'Round'}).and_return(TestId.new)

    matcher = RecordIdMatcher.new(sf, 'Object', [{Name: 'TestName', Id: 'TestId'}, {Type: 'TestType'}, {Color: 'Blue', Shape: 'Round'}])
    matcher.call({}).should eq 'TestId'
  end

  it "should return match as soon as it finds one" do
    sf = mock('Salesforce')
    sobject = mock('SalesforceObject')

    sf.should_receive(:[]).any_number_of_times.with('Object').and_return(sobject)
    sobject.should_receive(:where).with({Name: 'TestName', Id: 'TestId'})
    sobject.should_receive(:where).with(Type: 'TestType').and_return(TestId.new)

    matcher = RecordIdMatcher.new(sf, 'Object', [{Name: 'TestName', Id: 'TestId'}, {Type: 'TestType'}, {Color: 'Blue', Shape: 'Round'}])
    matcher.call({}).should eq 'TestId'
  end

  it "should raise an exception if no match is found" do
    sf = mock('Salesforce')
    sobject = mock('SalesforceObject')

    sf.should_receive(:[]).any_number_of_times.with('Object').and_return(sobject)
    sobject.should_receive(:where).with({Name: 'TestName', Id: 'TestId'})
    sobject.should_receive(:where).with(Type: 'TestType')
    sobject.should_receive(:where).with({Color: 'Blue', Shape: 'Round'})

    matcher = RecordIdMatcher.new(sf, 'Object', [{Name: 'TestName', Id: 'TestId'}, {Type: 'TestType'}, {Color: 'Blue', Shape: 'Round'}])
    lambda { matcher.call({}) }.should raise_exception(DataException)
  end

  it "should raise an exception if mutiple matches are found" do
    sf = mock('Salesforce')
    sobject = mock('SalesforceObject')

    sf.should_receive(:[]).any_number_of_times.with('Object').and_return(sobject)
    sobject.should_receive(:where).with({Name: 'TestName', Id: 'TestId'}).and_return(['One', 'Two'])

    matcher = RecordIdMatcher.new(sf, 'Object', [{Name: 'TestName', Id: 'TestId'}, {Type: 'TestType'}, {Color: 'Blue', Shape: 'Round'}])
    lambda { matcher.call({}) }.should raise_exception(DataException)
  end
end

describe Salesforce do
  it "should know if its connected to a production org" do
    salesforce_org = SalesforceOrg.create( username: 'username', password: 'password', token: 'sec_token', sandbox: false)
    SalesforceConnection.should_receive(:new).with({host: 'https://www.salesforce.com/services/Soap/u/22.0', username: 'username', password: 'password', sec_token: 'sec_token'})
    sf = Salesforce.new(salesforce_org)
    sf.is_sandbox?.should be_false
  end

  it "should know if its connected to a Sandbox" do
    salesforce_org = SalesforceOrg.create( username: 'username', password: 'password', token: 'sec_token', sandbox: true)
    SalesforceConnection.should_receive(:new).with({host: 'https://test.salesforce.com/services/Soap/u/22.0', username: 'username', password: 'password', sec_token: 'sec_token'})
    sf = Salesforce.new(salesforce_org)
    sf.is_sandbox?.should be_true
  end

  it "caches all object records and makes them available" do
    salesforce_object1 = mock('salesforce_object1')
    salesforce_object2 = mock('salesforce_object2')

    salesforce_org = SalesforceOrg.create( username: 'username', password: 'password', token: 'sec_token', sandbox: false)
    SalesforceConnection.should_receive(:new).with({host: 'https://www.salesforce.com/services/Soap/u/22.0', username: 'username', password: 'password', sec_token: 'sec_token'})
    sf = Salesforce.new(salesforce_org)

    SalesforceObject.should_receive(:new).with(sf, 'Object1', '', []).and_return(salesforce_object1)
    SalesforceObject.should_receive(:new).with(sf, 'Object2', '', []).and_return(salesforce_object2)

    salesforce_object1.should_receive(:all).any_number_of_times.and_return([0, 1])
    salesforce_object2.should_receive(:all).any_number_of_times.and_return([2, 3])

    sf.cache('Object1')
    sf.cache('Object2')
    sf['Object1'].all.should eq [0, 1]
    sf['Object2'].all.should eq [2, 3]
  end

  it "backs up all object records and makes them available" do
    salesforce_object = mock('salesforce_object')

    SalesforceObject.should_receive(:new).and_return(salesforce_object)
    salesforce_org = SalesforceOrg.create( username: 'username', password: 'password', token: 'sec_token', sandbox: false)
    SalesforceConnection.should_receive(:new).with({host: 'https://www.salesforce.com/services/Soap/u/22.0', username: 'username', password: 'password', sec_token: 'sec_token'})
    sf = Salesforce.new(salesforce_org)

    salesforce_object.should_receive(:all).any_number_of_times.and_return([0, 1])
    salesforce_object.should_receive(:backup)

    sf.backup('Object1')
    sf['Object1'].all.should eq [0, 1]
  end

  it "caches a subset of object records and makes them available" do
    salesforce_object = mock('salesforce_object')

    salesforce_org = SalesforceOrg.create( username: 'username', password: 'password', token: 'sec_token', sandbox: false)
    SalesforceConnection.should_receive(:new).with({host: 'https://www.salesforce.com/services/Soap/u/22.0', username: 'username', password: 'password', sec_token: 'sec_token'})
    sf = Salesforce.new(salesforce_org)

    SalesforceObject.should_receive(:new).with(sf, 'Object1', "One__c = 'One'", []).and_return(salesforce_object)
    salesforce_object.should_receive(:all).any_number_of_times.and_return([0, 1])

    sf.cache("Object1 where One__c = 'One'")
    sf['Object1'].all.should eq [0, 1]
  end

  it "should raise an exception for an uncached object" do
    salesforce_org = SalesforceOrg.create( username: 'username', password: 'password', token: 'sec_token', sandbox: false)
    SalesforceConnection.should_receive(:new).with({host: 'https://www.salesforce.com/services/Soap/u/22.0', username: 'username', password: 'password', sec_token: 'sec_token'})
    sf = Salesforce.new(salesforce_org)

    lambda { sf['Object2'] }.should raise_error(ArgumentError)
  end

  it "adds additional parameters for cached objects" do
    connection = mock('connection')
    sobject1 = mock('sobject1')
    sobject2 = mock('sobject2')
    sobject3 = mock('sobject3')

    salesforce_org = SalesforceOrg.create( username: 'username', password: 'password', token: 'sec_token', sandbox: false)
    SalesforceConnection.should_receive(:new).with({host: 'https://www.salesforce.com/services/Soap/u/22.0', username: 'username', password: 'password', sec_token: 'sec_token'}).and_return(connection)
    sf = Salesforce.new(salesforce_org)

    sf.should_receive(:materialize_with_fields).with('Object1', ['Id2']).and_return(sobject1)
    sf.should_receive(:materialize_with_fields).with('Object2', ['Id2', 'Id3']).and_return(sobject2)
    sf.should_receive(:materialize).with('Object3').and_return(sobject3)

    sobject1.should_receive(:all)
    sobject2.should_receive(:all)
    sobject3.should_receive(:all)

    sf.cache('Object1', 'Id2')
    sf.cache('Object2', 'Id2', 'Id3')
    sf.cache('Object3')
  end

  it "should describe an object" do
    connection = mock('connection')
    sobject = mock('SObject')

    salesforce_org = SalesforceOrg.create( username: 'username', password: 'password', token: 'sec_token', sandbox: false)
    SalesforceConnection.should_receive(:new).with({host: 'https://www.salesforce.com/services/Soap/u/22.0', username: 'username', password: 'password', sec_token: 'sec_token'}).and_return(connection)
    sf = Salesforce.new(salesforce_org)

    sf.should_receive(:materialize).with('Object3').and_return(sobject)

    sf.describe('Object3')
  end
end

describe SalesforceField do
  it "should do a null conversion by default (return the value passed for conversion" do
    sfield = SalesforceField.new({'type' => 'unknown', 'length' => 5})
    sfield.convert('1234567890').should eq '1234567890'
  end

  it "should do a length conversion on a string" do
    sfield = SalesforceField.new({'type' => 'string', 'length' => 5})
    sfield.convert('1234567890').should eq '12345'
  end

  it "should remove any text after a phone number" do
    sfield = SalesforceField.new({'type' => 'phone', 'length' => 15})
    sfield.convert('+0(1) 234 1234 only call in the day time').should eq '+0(1) 234 1234'
  end

  it "shouldn't do a length conversion on a string shorter than maximum length" do
    sfield = SalesforceField.new({'type' => 'string', 'length' => 15})
    sfield.convert('1234567890').should eq '1234567890'
  end

  it "should use short value Ids for long ones" do
    sfield = SalesforceField.new({'type' => 'id'})
    sfield.value('123456789012345678').should eq '123456789012345'
  end

  it "should convert common boolean values" do
    sfield = SalesforceField.new({'type' => 'boolean'})
    sfield.convert('').should eq ''
    sfield.convert(true).should be_true
    sfield.convert('TRUE').should be_true
    sfield.convert('True').should be_true
    sfield.convert('YES').should be_true
    sfield.convert('Yes').should be_true
    sfield.convert('T').should be_true
    sfield.convert('t').should be_true
    sfield.convert('1').should be_true
    sfield.convert('Y').should be_true
    sfield.convert('y').should be_true
    sfield.convert(false).should be_false
    sfield.convert('FALSE').should be_false
    sfield.convert('False').should be_false
    sfield.convert('NO').should be_false
    sfield.convert('No').should be_false
    sfield.convert('F').should be_false
    sfield.convert('f').should be_false
    sfield.convert('0').should be_false
    sfield.convert('N').should be_false
    sfield.convert('n').should be_false
  end
end

describe SalesforceObject do
  it "caches SalesforceObject" do
    salesforce = mock('salesforce')
    sobject = mock('sobject')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject)
    sfo = SalesforceObject.new(salesforce, 'Object1')
    SalesforceObject['Object1'].should be sfo
  end

  it "returns all records" do
    salesforce = mock('salesforce')
    sobject = mock('sobject')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject)
    sobject.should_receive(:all).and_return([0, 1])

    sfo = SalesforceObject.new(salesforce, 'Object1')
    sfo.all.should eq [0, 1]
  end

  it "returns all unique values of a property" do
    salesforce = mock('salesforce')
    sobject = mock('sobject')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject)
    sobject.should_receive(:all).and_return([{prop: 'One'}, {prop: 'Two'}, {prop: 'Two'}])
    sobject.should_receive(:describe_field).any_number_of_times.and_return({'type' => 'default'})

    sfo = SalesforceObject.new(salesforce, 'Object1')
    sfo.uniq('prop').should eq ['One', 'Two']
  end

  it "returns all unique values of a property including short form ids" do
    salesforce = mock('salesforce')
    sobject = mock('sobject')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject)
    sobject.should_receive(:all).and_return([{Id: '123456789012345678'}, {Id: '223456789012345678'}])
    sobject.should_receive(:describe_field).any_number_of_times.and_return({'type' => 'default'})

    sfo = SalesforceObject.new(salesforce, 'Object1')
    sfo.uniq('Id').should eq ['123456789012345678', '223456789012345678']
  end

  it "returns all unique values of a property excluding nils and empties" do
    salesforce = mock('salesforce')
    sobject = mock('sobject')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject)
    sobject.should_receive(:all).and_return([{prop: 'One'}, {prop: 'Two'}, {prop: 'Two'}, {prop: nil}, {prop: ''}])
    sobject.should_receive(:describe_field).any_number_of_times.and_return({'type' => 'default'})

    sfo = SalesforceObject.new(salesforce, 'Object1')
    sfo.uniq('prop').should eq ['One', 'Two']
  end

  it "returns an array of all matching records" do
    salesforce = mock('salesforce')
    sobject = mock('sobject')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject)
    sobject.should_receive(:all).and_return([{prop: 'One'}, {prop: 'Two'}, {prop: 'Two'}, {prop: nil}, {prop: ''}])
    sobject.should_receive(:describe_field).any_number_of_times.and_return({'type' => 'default'})

    sfo = SalesforceObject.new(salesforce, 'Object1')
    sfo.where(prop: 'Two').should eq [{prop: 'Two'}, {prop: 'Two'}]
  end

  it "returns a single matching record" do
    salesforce = mock('salesforce')
    sobject = mock('sobject')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject)
    sobject.should_receive(:all).and_return([{prop: 'One'}, {prop: 'Two'}, {prop: 'Two'}, {prop: nil}, {prop: ''}])
    sobject.should_receive(:describe_field).any_number_of_times.and_return({'type' => 'default'})

    sfo = SalesforceObject.new(salesforce, 'Object1')
    sfo.where(prop: 'One').should eq({prop: 'One'})
  end

  it "returns a single matching record on long and short ids" do
    salesforce = mock('salesforce')
    sobject = mock('sobject')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject)
    sobject.should_receive(:all).and_return([{Id: '123456789012345678'}])
    sobject.should_receive(:describe_field).any_number_of_times.with('Id').and_return({'type' => 'id'})

    sfo = SalesforceObject.new(salesforce, 'Object1')
    sfo.where(Id: '123456789012345').should eq({Id: '123456789012345678'})
  end

  it "returns a single matching record on long and short account ids" do
    salesforce = mock('salesforce')
    sobject = mock('sobject')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject)
    sobject.should_receive(:all).and_return([{AccountId: '123456789012345678'}])
    sobject.should_receive(:describe_field).any_number_of_times.with('AccountId').and_return({'type' => 'id'})

    sfo = SalesforceObject.new(salesforce, 'Object1')
    sfo.where(AccountId: '123456789012345').should eq({AccountId: '123456789012345678'})
  end

  it "returns no matching records" do
    salesforce = mock('salesforce')
    sobject = mock('sobject')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject)
    sobject.should_receive(:all).and_return([{prop: 'One'}, {prop: 'Two'}, {prop: 'Two'}, {prop: nil}, {prop: ''}])
    sobject.should_receive(:describe_field).any_number_of_times.and_return({'type' => 'default'})

    sfo = SalesforceObject.new(salesforce, 'Object1')
    sfo.where(prop: 'Three').should eq nil
  end

  it "returns a single matching record with compound key" do
    salesforce = mock('salesforce')
    sobject = mock('sobject')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject)
    sobject.should_receive(:all).and_return([{prop1: 'One', prop2: 'Two', prop3: 'Three'}, {prop1: 'One'}, {prop2: 'Two'}, {prop: nil}, {prop: ''}])
    sobject.should_receive(:describe_field).any_number_of_times.and_return({'type' => 'default'})

    sfo = SalesforceObject.new(salesforce, 'Object1')
    sfo.where(prop1: 'One', prop2: 'Two').should eq({prop1: 'One', prop2: 'Two', prop3: 'Three'})
    sfo.where(prop1: 'One', prop2: 'Two', prop3: 'Three').should eq({prop1: 'One', prop2: 'Two', prop3: 'Three'})
  end

  it "should back up all object records" do
    directory_name = 'backup'
    Dir::mkdir(directory_name) unless File.exists?(directory_name)

    salesforce = mock('salesforce')
    sobject1 = mock('sobject1')
    rec1 = mock('rec1')
    rec2 = mock('rec2')
    rec3 = mock('rec3')

    salesforce.should_receive(:materialize).with('Object1').and_return(sobject1)
    sobject1.should_receive(:all).and_return([rec1, rec2, rec3])
    rec1.should_receive(:attributes).any_number_of_times.and_return('First' => 'One', 'Second' => 'Two', 'Third' => 'Three')
    rec2.should_receive(:attributes).any_number_of_times.and_return('First' => '1', 'Second' => '2', 'Third' => '3')
    rec3.should_receive(:attributes).any_number_of_times.and_return('First' => 'A', 'Second' => 'B', 'Third' => 'C')

    rec1.should_receive(:[]).with('First').and_return('One');
    rec2.should_receive(:[]).with('First').and_return('1');
    rec3.should_receive(:[]).with('First').and_return('A');
    rec1.should_receive(:[]).with('Second').and_return('Two');
    rec2.should_receive(:[]).with('Second').and_return('2');
    rec3.should_receive(:[]).with('Second').and_return('B');
    rec1.should_receive(:[]).with('Third').and_return('Three');
    rec2.should_receive(:[]).with('Third').and_return('3');
    rec3.should_receive(:[]).with('Third').and_return('C');

    sfo = SalesforceObject.new(salesforce, 'Object1')
    filename = sfo.backup
    rows = CSV.read(filename, {headers: true, encoding: "utf-8"})
    rows[0]['First'].should eq 'One'
    rows[0]['Second'].should eq 'Two'
    rows[0]['Third'].should eq 'Three'
    rows[1]['First'].should eq '1'
    rows[1]['Second'].should eq '2'
    rows[1]['Third'].should eq '3'
    rows[2]['First'].should eq 'A'
    rows[2]['Second'].should eq 'B'
    rows[2]['Third'].should eq 'C'
  end

end

describe ConvertibleCSVRow do
  it "returns row values" do
    sobject = mock('SalesforceObject')
    sfield = SalesforceField.new

    sobject.should_receive(:describe_field).any_number_of_times.with(any_args()).and_return(sfield)

    ccr = ConvertibleCSVRow.new({'one' => 'One', 'two' => 'Two'}, 0, sobject, ['one', 'two'], [], nil)
    ccr['one'].should eq 'One'
    ccr['two'].should eq 'Two'
  end

  it "sets row values" do
    sobject = mock('SalesforceObject')
    sfield = SalesforceField.new

    sobject.should_receive(:describe_field).any_number_of_times.with(any_args()).and_return(sfield)

    ccr = ConvertibleCSVRow.new({'one' => 'One', 'two' => 'Two'}, 0, sobject, ['one', 'two'], [], nil)
    ccr['three'] = 'Three'
    ccr['three'].should eq 'Three'
  end

  it "overrides row values" do
    sobject = mock('SalesforceObject')
    sfield = SalesforceField.new

    sobject.should_receive(:describe_field).any_number_of_times.with(any_args()).and_return(sfield)

    ccr = ConvertibleCSVRow.new({'one' => 'One', 'two' => 'Two'}, 0, sobject, ['one', 'two'], [], nil)
    ccr['one'] = 'Three'
    ccr['one'].should eq 'Three'
  end

  it "converts values" do
    sobject = mock('SalesforceObject')
    sfield = SalesforceField.new

    sobject.should_receive(:describe_field).any_number_of_times.with(any_args()).and_return(sfield)

    output = []
    ccr = ConvertibleCSVRow.new({'one' => 'One', 'two' => 'Two'}, 0, sobject, ['one', 'two'], [], output)
    ccr.convert
    output[0].should eq ['One', 'Two']
    ccr.converted?.should be_true
  end

  it "converts values according to type" do
    sobject = mock('SalesforceObject')
    sfield1 = SalesforceField.new
    sfield2 = SalesforceField.new({'type' => 'string', 'length' => 1})

    sobject.should_receive(:describe_field).any_number_of_times.with('one').and_return(sfield1)
    sobject.should_receive(:describe_field).any_number_of_times.with('two').and_return(sfield2)

    output = []
    ccr = ConvertibleCSVRow.new({'one' => 'One', 'two' => 'Two'}, 0, sobject, ['one', 'two'], [], output)
    ccr.convert
    output[0].should eq ['One', 'T']
    ccr.converted?.should be_true
  end

  it "doesn't convert values not listed as valid columns" do
    sobject = mock('SalesforceObject')
    sfield = SalesforceField.new

    sobject.should_receive(:describe_field).any_number_of_times.with(any_args()).and_return(sfield)

    output = []
    ccr = ConvertibleCSVRow.new({'one' => 'One', 'two' => 'Two', 'three' => 'Three'}, 0, sobject, ['one', 'two'], [], output)
    ccr.converted?.should be_false
    ccr.convert
    output[0].should eq ['One', 'Two']
    ccr.converted?.should be_true
  end
end

