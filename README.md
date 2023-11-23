# OBD2 Flutter iOS Plugin

obd2_flutter_plugin is an iOS plugin to be used in Flutter applications that allows users to monitor and interact with an OBD2 adapter to retrieve and display vehicle information.

## Features

- **Bluetooth Connectivity:** Establishes a connection with an OBD2 adapter over Bluetooth LE.
- **OBD2 Commands:** Sends commands to the adapter and retrieves vehicle data.
- **Display of Vehicle Information:** Shows various vehicle parameters like RPM, speed, fuel level, etc.

## Getting Started

To use this application, follow these steps:

**Clone the Repository:**

    git clone https://github.com/typ-AhmedSleem/obd2_ios_flutter_plugin.git

**Add Dependency:**

1. **Place 'obd2_flutter_plugin' in project root directory.**

2. **Add dependency in pubspec.yaml**

```yaml
obd2_flutter_plugin:
  path: "../"
```

**Run app:**

`Deploy your app to iOS device to use plugin functionality.`

## Usage

`Please refer to example app for how to use the plugin.`
- Ensure your device has Bluetooth enabled.
- Launch the app and grant necessary permissions for Bluetooth access.
- Pair the app with your OBD2 adapter.
- Explore the different screens to view vehicle information.

## Requirements

- Flutter SDK
- Supported device with Bluetooth capabilities
- OBD2 adapter compatible with the app (refer to supported adapters in code)

## Contributing

Contributions are welcome! If you'd like to contribute to this project, please follow these guidelines:

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/MyAwesomeFeature`).
3. Commit your changes (`git commit -a -m 'Add some feature'`).
4. Push to the branch (`git push origin feature/MyAwesomeFeature`).
5. Open a pull request.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgements

- [Flutter](https://flutter.dev/) - Flutter SDK by Google
- [OBD-II](https://en.wikipedia.org/wiki/OBD-II_PIDs) - OBD-II Protocol Information

## Contact

For any inquiries or suggestions, feel free to contact the project maintainer at [typahmedsleem@gmail.com](mailto:typahmedsleem@gmail.com).
