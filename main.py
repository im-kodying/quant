from nautilus_trader.adapters.interactive_brokers.config import DockerizedIBGatewayConfig
from nautilus_trader.adapters.interactive_brokers.gateway import DockerizedIBGateway
import subprocess


def main():
    print("Starting Quant Trading Platform . . .")
    subprocess.call("echo $(ls -l /var/run/docker.sock)")
    subprocess.call("echo $(docker info)")
    gateway_config = DockerizedIBGatewayConfig(
        username="imkodying",
        password="cvNQOH3qRAT3ze8F5yr4",
        trading_mode="paper",
    )

    # This may take a short while to start up, especially the first time
    gateway = DockerizedIBGateway(
        config=gateway_config
    )
    gateway.start()

    # Confirm you are logged in
    print(gateway.is_logged_in(gateway.container))

    # Inspect the logs
    print(gateway.container.logs())
    return


if __name__ == "__main__":
    main()
