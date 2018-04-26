#include <pcap.h>
#include <cstdlib>
#include <iostream>
#include "PcapUtil.h"
#include <getopt.h>
#include <ctime>
#include <cstring>
#include "DHCPMsg.h"
#include <unistd.h>
#include <map>
#include <chrono>
#include <netinet/in.h>

using namespace std;

int main(int argc, char *argv[])
{
	if (argc != 3) {
		cerr << "invalid number of arguments" << endl;
		return EXIT_FAILURE;
	}
	string devName;
	int c;
	while ((c = getopt(argc, argv, "i:")) != -1) {
		switch (c){
		case 'i':
			devName = optarg;
			break;
		default:
			cerr << "invalid arguments" << endl;
			return EXIT_FAILURE;
		}
	}

	const set<string> allDevices = PcapUtil::allDevices();
	auto it = allDevices.find(devName);
	if (it == allDevices.end()) {
		string err;
		err += "unknown device name: ";
		err += devName;
		err += "\n";
		err += "all fond devices: ";

		if (allDevices.size() > 1) {
			for (const auto &dev : allDevices)
				err += dev + ", ";

			// remove last two chars
			err.pop_back();
			err.pop_back();
		}
		else {
			err += "ziadne zariadenie nebolo najdete";
		}

		cerr << err << endl;
		return EXIT_FAILURE;
	}
	srand(time(nullptr));

	std::map<uint32_t, DHCPMsgInfo> packets;

	pcap_t *handle;
	char errbuff[PCAP_ERRBUF_SIZE] = {0};
	handle = pcap_open_live(devName.c_str(), 512, 1, -1, errbuff);
	if (strlen(errbuff) > 0) {
		cerr << errbuff << endl;
		return -1;
	}

	struct bpf_program filter;
	char filter_exp[] = "port 68";
	bpf_u_int32 ip;
	if (pcap_compile(handle, &filter, filter_exp, 0, ip) == -1) {
		printf("Bad filter - %s\n", pcap_geterr(handle));
		return 2;
	}
	if (pcap_setfilter(handle, &filter) == -1) {
		printf("Error setting filter - %s\n", pcap_geterr(handle));
		return 2;
	}

	DHCPMessage msg;
	//msg.setEthMAC({0x1c, 0x1b, 0x0d, 0x04, 0x7d, 0x50}); // pc
	msg.setEthMAC({0x68, 0x5d, 0x43, 0x2b, 0xc5, 0x37}); // ntb wifi
	msg.setFakeClientMAC({0x2c, 0x1b, 0x0d, 0x04, 0x7d, 0x50});
	msg.setTransactionID(0xab789450);

	auto *buffer = new uint8_t[1024];
	size_t velkost = msg.raw(buffer);
	pcap_sendpacket(handle, (const u_char *) buffer, velkost);

	packets.emplace(make_pair(0xab789450, DHCPMsgInfo{123,
		PcapUtil::timestamp(),PcapUtil::timestamp(),PcapUtil::timestamp(),1}));

	uint64_t startTime = PcapUtil::timestamp();

	while (true) {
		uint8_t *buf = new uint8_t[1024];

		struct pcap_pkthdr header;
		header.len = 0;
		buf = (uint8_t *) pcap_next(handle, &header);

		if (PcapUtil::timestamp() - startTime > 1000)
			break;


		if (header.len == 0)
			continue;

		TEthHeader *h1 = (TEthHeader *) buf;
		cout << h1->toString("\n") << endl;


		TIP4Header *h2 = (TIP4Header *) (buf + h1->raw().size());
		cout << h2->toString("\n") << endl;

		TUDPHeader *h3 = (TUDPHeader *) (buf + h1->raw().size() + h2->raw().size());
		cout << h3->toString("\n") << endl;

		TDHCPHeader *h4 = (TDHCPHeader *) (buf + h1->raw().size() + h2->raw().size() + h3->raw().size());
		cout << h4->toString("\n") << endl;

		TDHCPData *h5 = (TDHCPData *) (buf + h1->raw().size() + h2->raw().size() + h3->raw().size() + h4->raw().size());
		cout << h5->toString("\n") << endl;

		auto it = packets.find(h4->transactionID);
		if (it ==  packets.end())
			cerr << "koniec" << endl;
		else
			cerr << "najdene" << endl;
	}


	pcap_close(handle);

	return EXIT_SUCCESS;
}
