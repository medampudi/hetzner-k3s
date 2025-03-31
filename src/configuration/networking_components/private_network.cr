require "ipaddress"
require "./tailscale"

class Configuration::NetworkingComponents::PrivateNetwork
  include YAML::Serializable
  include YAML::Serializable::Unmapped

  getter enabled : Bool = true
  getter subnet : String = "10.0.0.0/16"
  getter existing_network_name : String = ""
  getter mode : String = "hetzner"
  getter tailscale : Configuration::NetworkingComponents::Tailscale = Configuration::NetworkingComponents::Tailscale.new

  def initialize
  end

  def validate(errors, hetzner_client)
    validate_existing_network_name(errors, hetzner_client)
    validate_mode(errors)
    validate_tailscale(errors) if tailscale?

    begin
      IPAddress.new(subnet).network?
    rescue ArgumentError
      errors << "private network subnet #{subnet} is not a valid network in CIDR notation"
    end
  end

  private def validate_existing_network_name(errors, hetzner_client)
    return if existing_network_name.empty?

    return if Hetzner::Network::Find.new(hetzner_client, existing_network_name).run

    errors << "You have specified that you want to use the existing network named '#{existing_network_name}' but this network doesn't exist"
  end

  private def validate_mode(errors)
    unless ["hetzner", "tailscale"].includes?(mode)
      errors << "private network mode must be either 'hetzner' or 'tailscale'"
    end
  end

  private def tailscale?
    mode == "tailscale"
  end

  private def validate_tailscale(errors)
    tailscale.validate(errors)
  end
end
