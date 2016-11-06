/**
 * @file main.cpp
 * @Author Peter Tisovčík <xtisov00@stud.fit.vutbr.cz>
 * @date October, 2016
 */

#include <algorithm>
#include <iostream>
#include <iomanip>

#include "ArgumentParser.h"
#include "LayerMessage.h"
#include "PcapReaderFromFile.h"
#include "Statistics.h"

#include "GenericLayerMessageFactory.h"
#include "LinkLayerMessageFactory.h"
#include "NetworkLayerMessageFactory.h"
#include "TransportLayerMessageFactory.h"

using namespace std;

int main(int argc, char * argv[])
{
	ArgumentParser args;
	args.setOption("i", "input file (pcap format)",
		true,
		"<file>",
		true);
	args.setOption("f", "filter type: mac, ipv4, ipv6, tcp, udp",
		true,
		"filter",
		true);
	args.setOption("v", "5C:D5:96:2C:38:63(MAC), 192.168.1.1(IPv4), 2001::1(IPv6), 80 (TCP, UDP), top10(mac, ipv4, ipv6, tcp, udp)",
		true,
		"<file>",
		true);
	args.setOption("s", "filter for source address",
		false,
		"",
		false);
	args.setOption("d", "filter for destination address",
		false,
		"",
		false);

	//kontrola ci sa spracovali argumenty uspesne
	try {
		if (!args.validateArguments(argc, argv))
			return EXIT_FAILURE;
	}
	catch (exception &ex) {
		cerr << ex.what() << endl;
		return EXIT_FAILURE;
	}

	Statistics statistics;
	GenericLayerMessageFactory factory;
	shared_ptr<LayerMessage> layerMessage;

	factory.registerLayer(LINK_LAYER, shared_ptr<LayerMessageFactory>(new LinkLayerMessage()));
	factory.registerLayer(NETWORK_LAYER, shared_ptr<LayerMessageFactory>(new NetworkLayerMessage()));
	factory.registerLayer(TRANSPORT_LAYER, shared_ptr<LayerMessageFactory>(new TransportLayerMessage()));

	ifstream file(args.getArgument("i"), ios::in|ios::binary);
	file.seekg(0, ios::end);
	int end = file.tellg();
	file.seekg(0, ios::beg);

	//test ci sa subor otvoril spravne
	if (!file.is_open())
		return EXIT_FAILURE;

	//struktura popisujuca vstup, pre triedu PcapReader
	Input input({file, std::vector<uint8_t>()});

	//preskocenie hlavicky pocap suboru
	PcapReaderFromFile reader(input.file);
	reader.skip(24);

	//ziskanie filtrov a ip adries z argumentov
	LayerMessage optionMessage = args.getLayersMessage();

	//vrstva po ktoru sa ma parsovat sprava
	vector<string> enteredFilter = args.getFilter();
	Layer layer = optionMessage.extractHighestLayer(enteredFilter);

	optionMessage.show();

	string keyS, keyD;
	while(file.tellg() < end) {
		try {
			layerMessage = factory.create(input, layer);
			file.close();
		}
		catch (exception &ex) {
			cerr << ex.what();
			break;
		}
		layerMessage->show();

		//prechod dostupnymi filtrami
		for (const auto &item : filterType) {
			//kontrola si sa prehladavany typ filtra zadal
			if (find(enteredFilter.begin(), enteredFilter.end(), item) == enteredFilter.end())
				continue;

			auto search = optionMessage.address.find(
				optionMessage.extractProtocol(item));
			auto search2 = layerMessage->address.find(
				layerMessage->extractProtocol(item));

			if (args.isTop10()) {
				if (search2 == layerMessage->address.end())
					continue;

				//vytvorenie kluca podla ktoreho sa bude ukladat
				keyS = search2->second.sourceAddress[0];
				keyD = search2->second.destinationAddress[0];

				if (optionMessage.source)
					statistics.insert(keyS, 0, 0);

				if (optionMessage.destination)
					statistics.insert(keyD, 0, 0);
			}
			else {
				if (search == optionMessage.address.end()
					|| search2 == layerMessage->address.end())
					continue;

				if (item == "mac") {
					keyS = search2->second.sourceAddress[0];
					keyD = search2->second.destinationAddress[0];
				}

				if (optionMessage.destination) {
					for (const auto &add : search->second.sourceAddress) {
						if (add == search2->second.sourceAddress[0])
							statistics.insert(add, 0, 0);
					}
				}

				if (optionMessage.source) {
					for (const auto &add : search->second.destinationAddress) {
						if (add == search2->second.destinationAddress[0])
							statistics.insert(add, 0, 0);
					}
				}
			}
		} //koniec prechodu medzi filtrami

		break;
	}

	cout << "--------Statistika----------\n";
	statistics.showTop10();
	cout << "--------Statistika2---------\n";
	statistics.showFilterStatistics();
	cout << "----------------------------\n";

	return 0;
}