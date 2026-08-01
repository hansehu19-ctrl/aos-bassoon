import os
import sys
import time
import argparse
import grpc
from concurrent import futures

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))
from core.proto import aos_rpc_pb2, aos_rpc_pb2_grpc

class MockIVNServer(aos_rpc_pb2_grpc.IVNGatewayServicer):
    def ExecuteCommand(self, request, context):
        print(f"\n[MOCK VM] Received: {request.exec_path} {list(request.args)}")
        if request.exec_path == "cat01_validator":
            return aos_rpc_pb2.CommandResponse(
                metadata=aos_rpc_pb2.Metadata(
                    request_id=request.metadata.request_id,
                    caller="Mock-VM",
                    callee="CAT01"
                ),
                status=aos_rpc_pb2.STATUS_SUCCESS,
                exit_code=0,
                stdout_data=b'{"asset_hash":"deadbeef","risk_level":"LOW"}',
                stderr_data=b"",
                duration_ms=10
            )
        return aos_rpc_pb2.CommandResponse(
            metadata=aos_rpc_pb2.Metadata(request_id=request.metadata.request_id),
            status=aos_rpc_pb2.STATUS_SUCCESS,
            exit_code=0,
            stdout_data=b"MOCK_OK",
            stderr_data=b"",
            duration_ms=5
        )

def serve(sock_path="/tmp/aos_ivn_mock.sock"):
    if os.path.exists(sock_path):
        os.remove(sock_path)
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=4))
    aos_rpc_pb2_grpc.add_IVNGatewayServicer_to_server(MockIVNServer(), server)
    server.add_insecure_port(f"unix://{sock_path}")
    server.start()
    print(f"[Mock VM] Listening on {sock_path}")
    try:
        while True:
            time.sleep(86400)
    except KeyboardInterrupt:
        server.stop(0)
    finally:
        if os.path.exists(sock_path):
            os.remove(sock_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--sock-path", default="/tmp/aos_ivn_mock.sock")
    args = parser.parse_args()
    serve(args.sock_path)
