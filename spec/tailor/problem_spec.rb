require_relative '../spec_helper'
require 'tailor/problem'

describe Tailor::Problem do
  describe "#initialize" do
    it "accepts a Binding" do
      stuff = "HI"
      lineno = 0
      column = 0
      type = :test
      problem = Tailor::Problem.new(type, binding)
      problem.instance_variable_get(:@binding).eval("stuff").should == "HI"
    end
  end

  describe "#set_values" do
    let(:lineno) { 10 }
    let(:column) { 11 }

    it "sets self[:type] to the type param" do
      binding = double "Binding", eval: nil
      problem = Tailor::Problem.new(:test, binding)
      problem.should include(:type => :test)
    end

    it "sets self[:line] to 'lineno' from the binding" do
      problem = Tailor::Problem.new(:test, binding)
      problem.should include(line: 10)
    end

    it "sets self[:column] to 'column' from the binding" do
      problem = Tailor::Problem.new(:test, binding)
      problem.should include(column: 11)
    end

    it "sets self[:message] to what's returned from #message for @type" do
      Tailor::Problem.any_instance.should_receive(:message).with(:test).
        and_return("test message")

      problem = Tailor::Problem.new(:test, binding)
      problem.should include(message: "test message")
    end
  end

  describe "#message" do
    before do
      Tailor::Problem.any_instance.stub(:set_values)
    end

    context "type is :indentation" do
      it "builds a successful message" do
        @indentation_ruler = double "IndentationRuler"
        @indentation_ruler.stub(:actual_indentation).and_return 10
        @indentation_ruler.stub(:should_be_at).and_return 97
        problem = Tailor::Problem.new(:test, binding)
        problem.message(:indentation).should match /10.*97/
      end
    end

    context "type is :trailing_newlines" do
      it "builds a successful message" do
        trailing_newline_count = 123
        @config = { vertical_spacing: { trailing_newlines: 777 } }
        problem = Tailor::Problem.new(:test, binding)
        problem.message(:trailing_newlines).should match /123.*777/
      end
    end

    context "type is :hard_tab" do
      it "builds a successful message" do
        problem = Tailor::Problem.new(:test, binding)
        problem.message(:hard_tab).should match /Hard tab found./
      end
    end

    context "type is :line_length" do
      it "builds a successful message" do
        current_line_of_text = double "line of text", length: 88
        @config = { horizontal_spacing: { line_length: 77 } }
        problem = Tailor::Problem.new(:test, binding)
        problem.message(:line_length).should match /88.*77/
      end
    end
  end
end