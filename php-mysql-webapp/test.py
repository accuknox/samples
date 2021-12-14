from DocXMLRPCServer import DocXMLRPCServer, DocXMLRPCRequestHandler
from SocketServer import ThreadingMixIn
import time

class Stats:
    def getstats(self):
        return self.callstats

    def getruntime(self):
        return time.time() - self.starttime

    def failure(self):
        raise RuntimeError, "This function always raises an error."

class Math(Stats):
    def __init__(self):
        self.callstats = {'pow': 0, 'hex': 0}
        self.starttime = time.time()

    def pow(self, x, y):
        self.callstats['pow'] += 1
        return pow(x, y)

    def hex(self, x):
        self.callstats['hex'] += 1
        return "%x" % x

class ThreadingServer(ThreadingMixIn, DocXMLRPCServer):
    pass

serveraddr = ('', 8765)
srvr = ThreadingServer(serveraddr, DocXMLRPCRequestHandler)
srvr.set_server_title("Example Documentation")
srvr.set_server_name("Your name")
srvr.set_server_documentation("""Welcome to""")
srvr.register_instance(Math())
srvr.register_introspection_functions()
srvr.serve_forever()
