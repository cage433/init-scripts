#!/usr/bin/ruby -w

class Command
  def command
    raise "Not implemented"
  end

  def running?
    `pgrep -f -x \"#{command}\" > /dev/null 2>&1`
    $?.to_i == 0
  end

  def launch
    puts "Running '#{command}'"
    system("pkill",  "-f", "-x", command);
    system(command)
  end

  def ensure_running
    running? || launch
  end
end

class Tunnel < Command
  attr_reader :from_port, :to_host, :to_port, :remote_host
  def initialize(from_port, to_host, to_port, remote_host)
      @from_port = from_port
      @to_host = to_host
      @to_port = to_port
      @remote_host = remote_host
  end
end

class ForwardTunnel < Tunnel
  def initialize(from_port, to_host, to_port, remote_host)
    super(from_port, to_host, to_port, remote_host)
  end

  def command 
    "ssh -f -N -L #{from_port}:#{to_host}:#{to_port} #{remote_host}"
  end

  def self.build(line)
    from_port, to_host, to_port, remote_host = line.match(/L\s+(\d+)\s+(\w+)\s+(\d+)\s+((\w|\.)+)/).captures
    ForwardTunnel.new(from_port, to_host, to_port, remote_host)
  end

  def to_s
    "Forward tunnel: #{from_port} to #{to_host}:#{to_port} via #{remote_host}"
  end

end

class ReverseTunnel < Tunnel
  def initialize(from_port, to_host, to_port, remote_host)
    super(from_port, to_host, to_port, remote_host)
  end

  def command 
    "ssh -f -N -R #{from_port}:#{to_host}:#{to_port} #{remote_host}"
  end

  def self.build(line)
    from_port, to_host, to_port, remote_host = line.match(/R\s+(\d+)\s+(\w+)\s+(\d+)\s+((\w|\.)+)/).captures
    ReverseTunnel.new(from_port, to_host, to_port, remote_host)
  end

  def to_s
    "Reverse tunnel: #{from_port} to #{to_host}:#{to_port} via #{remote_host}"
  end

  def can_be_seen_remotely?
    remote_processes=`ssh #{remote_host} 'netstat -an'`.split("\n")
    remote_processes.any?{ |p| p =~ /tcp.*#{from_port}.*LISTEN/}
  end

  def ensure_running
    (running? && can_be_seen_remotely?) || launch
  end

end

class Socks < Command
  attr_reader :port, :remote_host
  def initialize(port, remote_host)
      @port = port
      @remote_host = remote_host
  end

  def self.build(line)
    port, remote_host = line.match(/D\s+(\d+)\s+((\w|\.)+)/).captures
    Socks.new(port, remote_host)
  end

  def command 
    "ssh -f -N -D #{port} #{remote_host}"
  end
end



def process_line(line)
  if line =~ /^#/ || line =~ /^\s+/ then
    # Ignore comments and lines beginning with whitespace
  elsif line =~ /^L/
    ForwardTunnel.build(line).ensure_running
  elsif line =~ /^R/
    ReverseTunnel.build(line).ensure_running
  elsif line =~ /D/
    Socks.build(line).ensure_running
  else
    raise "Can't process line #{line}"
  end
end

IO.readlines("#{ENV["HOME"]}/.tunnels").each do |line| 
  process_line line
end
