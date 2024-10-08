require "../client"
require "../instance"
require "../instances_list"
require "./find"
require "../../util"

class Hetzner::Instance::Delete
  include Util

  getter hetzner_client : Hetzner::Client
  getter instance_name : String
  getter instance_finder : Hetzner::Instance::Find

  private getter settings : Configuration::Main
  private getter ssh : Configuration::NetworkingComponents::SSH
  private getter ssh_client : Util::SSH do
    Util::SSH.new(ssh.private_key_path, ssh.public_key_path)
  end

  def initialize(@settings, @hetzner_client, @instance_name)
    @ssh = settings.networking.ssh
    @instance_finder = Hetzner::Instance::Find.new(@settings, @hetzner_client, @instance_name)
  end

  def run
    if instance = instance_finder.run
      log_line "Deleting instance #{instance_name}..."

      Retriable.retry(max_attempts: 10, backoff: false, base_interval: 5.seconds) do
        success, response = hetzner_client.delete("/servers", instance.id)

        if success
          log_line "...instance #{instance_name} deleted"
        else
          STDERR.puts "[#{default_log_prefix}] Failed to delete instance #{instance_name}: #{response}"
          STDERR.puts "[#{default_log_prefix}] Retrying to delete instance #{instance_name} in 5 seconds..."
          raise "Failed to delete instance"
        end
      end
    else
      log_line "Instance #{instance_name} does not exist, skipping delete"
    end

    instance_name
  end

  private def default_log_prefix
    "Instance #{instance_name}"
  end
end
