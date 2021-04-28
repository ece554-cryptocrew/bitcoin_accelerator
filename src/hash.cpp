#include <chrono>
#include <ctime>  
#include <iostream>
#include <sstream>
#include <string>
#include <fstream>
using namespace std;

int main(int argc, char** argv)
{
	if(argc < 3)
	{
		fprintf(stdout, "hash\n");
		fprintf(stdout, "hashes header nonce from zero until hits proper header then outputs stats\n");
		fprintf(stdout, "Usage: hash input bitcoinheader expected output hash\n");
		return 1;
	}
	//Get nonce as a decimal for calculations
	std::stringstream str;
	std::string str1= argv[1];
	std::string s1 = str1.substr(152, 159);
	str << std::hex << s1;
	unsigned int nonce;
	str >> nonce;

	//create host memor files
	ofstream host1("host1.txt");
	ofstream host2("host2.txt");
	ofstream host3("host3.txt");
	ofstream host4("host4.txt");
	ofstream host5("host5.txt");
	ofstream host6("host6.txt");
	ofstream host7("host7.txt");
	ofstream host8("host8.txt");
	ofstream correct("correctHash.txt");

	host1 << "0000\n0000\n0000\n5000\n";
	host1 << argv[1];
	host2 << "0000\n0000\n0000\n5100\n";
	host2 << argv[1];
	host3 << "0000\n0000\n0000\n6000\n";
	host3 << argv[1];
	host4 << "0000\n0000\n0000\n6100\n";
	host4 << argv[1];
	host5 << "0000\n0000\n0000\n7000\n";
	host5 << argv[1];
	host6 << "0000\n0000\n0000\n7100\n";
	host6 << argv[1];
	host7 << "0000\n0000\n0000\n8000\n";
	host7 << argv[1];
	host8 << "0000\n0000\n0000\n8100\n";
	host8 << argv[1];
	correct<< argv[2];

	host1.close();
	host2.close();
	host3.close();
	host4.close();
	host5.close();
	host6.close();
	host7.close();
	host8.close();
	correct.close();
	char command[50];
	//convert to bin files
	sprintf (command, "bin/x2b host1.txt host1.bin");
	system(command);
	sprintf (command, "bin/x2b host2.txt host2.bin");
	system(command);
	sprintf (command, "bin/x2b host3.txt host3.bin");
	system(command);
	sprintf (command, "bin/x2b host4.txt host4.bin");
	system(command);
	sprintf (command, "bin/x2b host5.txt host5.bin");
	system(command);
	sprintf (command, "bin/x2b host6.txt host6.bin");
	system(command);
	sprintf (command, "bin/x2b host7.txt host7.bin");
	system(command);
	sprintf (command, "bin/x2b host8.txt host8.bin");
	system(command);
	sprintf (command, "bin/x2b correctHash.txt correctHash.bin");
	system(command);

	//instruction code
	sprintf (command, "bin/class -i src/asmCode.asm -o instruct.bin");
	system(command);	
	//start timer
	auto start = std::chrono::system_clock::now();
	//run script to kick off fpga
	sprintf (command, "bin/cload_sim -i script.cload");
	system(command);
	auto end = std::chrono::system_clock::now();
	//output timing
	std::chrono::duration<double> elapsed_seconds = end-start;
	std::cout << "elapsed time: " << elapsed_seconds.count() << "s\n";
	std::cout << "total hashes: " << nonce << "\n";
	std::cout << "hashes per second: " << elapsed_seconds.count()/nonce << " hashes per sec\n";


	//sprintf (command, "rm host*");
	//system(command);
	//sprintf(command, "rm correctHash.*");
	//system(command);


}
