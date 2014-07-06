# coding: utf-8

class Benchmarking
  class << self
    attr_accessor :warm_up
    alias_method :warm_up?, :warm_up
    attr_writer :loop_count

    def loop_count
      @loop_count ||= 100
    end

    def pretty_time(time)
      format('%0.05f sec', time)
    end
  end

  attr_reader :name

  def initialize(name, &block)
    @name = name
    @process = block
  end

  def run
    @process.call
  end

  def time
    return @time if @time

    self.class.loop_count.times { run } if self.class.warm_up?

    beginning = Time.now
    self.class.loop_count.times { run }
    ending = Time.now

    @time = ending - beginning
  end

  def pretty_time
    self.class.pretty_time(time)
  end

  def inspect
    "#{name} (#{pretty_time})"
  end

  alias_method :to_s, :inspect
end

RSpec::Matchers.define :be_faster_than do |other|
  match do |subject|
    if @times
      subject.time < (other.time / @times)
    else
      subject.time < other.time
    end
  end

  {
          twice: 2,
    three_times: 3,
     four_times: 4,
     five_times: 5,
      six_times: 6,
    seven_times: 7
  }.each do |name, value|
    chain name do
      @times = value
    end
  end

  failure_message do |subject|
    other_label = other.name
    other_label << " / #{@times}" if @times

    label_width = [subject.name, other_label].map { |label| label.length }.max

    message = "#{subject.name.rjust(label_width)}: #{subject.pretty_time}\n"

    if @times
      message << "#{other_label.rjust(label_width)}: "
      shortened_other_time = Benchmarking.pretty_time(other.time / @times)
      message << "#{shortened_other_time} (#{other.pretty_time} / #{@times})"
    else
      message << "#{other_label.rjust(label_width)}: #{other.pretty_time}"
    end
  end
end

RSpec::Matchers.define :be_as_fast_as do |other|
  margin = 1.2

  match do |subject|
    subject.time < (other.time * margin)
  end

  failure_message do |subject|
    label_width = [subject, other].map { |b| b.name.length }.max

    [subject, other].map do |benchmark|
      "#{benchmark.name.rjust(label_width)}: #{benchmark.pretty_time}"
    end.join("\n")
  end
end