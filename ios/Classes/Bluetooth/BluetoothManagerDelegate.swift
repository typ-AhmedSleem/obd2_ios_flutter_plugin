// Created by AhmedSleem

protocol BluetoothManagerDelegate {

    optional func onAdapterConnected()
    optional func onAdapterInitialized()
    optional func onAdapterStateChanged(state: ObdState)
    optional func onAdapterDisconnected()
    optional func onAdapterReceiveResponse(response: String?)

}