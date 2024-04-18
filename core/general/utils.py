from pathlib import Path


def get_root() -> Path:
    return Path(__file__).absolute().parent.parent


class AESCypher:
    DECRYPT_KEY = 'HKLlbF514I09oYcv'

    def decrypt(self, msg: bytes) -> str:
        # aes = pyaes.AESModeOfOperationCTR(self.DECRYPT_KEY)
        # return aes.decrypt(msg)
        return str(msg, encoding='utf-8')

    def encrypt(self, msg: str) -> bytes:
        # aes = pyaes.AESModeOfOperationCTR(self.ENCRYPT_KEY)
        # return aes.decrypt(msg)
        return bytes(msg, encoding='utf-8')


SERVER_DIR: Path = get_root() / 'server'
CLIENT_DIR: Path = get_root() / 'client'
