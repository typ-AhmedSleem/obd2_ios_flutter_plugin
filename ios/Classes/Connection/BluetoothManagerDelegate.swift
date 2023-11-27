// Created by AhmedSleem

protocol BluetoothManagerDelegate {

     func onAdapterConnected()
     func onAdapterInitialized()
     func onAdapterStateChanged(state: Int)
     func onAdapterDisconnected()
     func onAdapterReceiveResponse(response: String?)

}
