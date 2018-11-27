
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <iostream>
#include <vector>
#include <fstream>
#include <string>
#include <stdio.h>
#include <Windows.h>
#include <time.h>
#include <thread>
#include <omp.h>
#include <vector>
#include <math.h>
#include <cmath>

using namespace std;

struct img_param {
	int size;
	int pixels_adress;
	int width;
	int height;
	short int bits_per_pixel;
};
struct px_arr {
	unsigned int *r;
	unsigned int *g;
	unsigned int *b;
};


px_arr reading(int dimensions1, int dimensions2, ifstream &file) {
	unsigned int r = 0;
	unsigned int g = 0;
	unsigned int b = 0;

	px_arr old;
	old.r = new unsigned int[dimensions1 * dimensions2];
	old.g = new unsigned int[dimensions1 * dimensions2];
	old.b = new unsigned int[dimensions1 * dimensions2];
	
	for (int i = 0; i < dimensions1 * dimensions2; i++) {
		file.read((char*)&b, 1);
		file.read((char*)&g, 1);
		file.read((char*)&r, 1);
		old.r[i] = r;
		old.g[i] = g;
		old.b[i] = b;

	}
	return old;
}

void small_width(unsigned int *r, unsigned int *g, unsigned int *b, int width, int height, int new_width, unsigned int *yr, unsigned int *yg, unsigned int *yb) {
	for (int i = 0; i < height; i++) {
		for (int j = 0; j < new_width; j++) {
			yr[new_width * i + j] = r[(int)round(((float)width / (float)new_width) * j + width * i)];
			yg[new_width * i + j] = g[(int)round(((float)width / (float)new_width) * j + width * i)];
			yb[new_width * i + j] = b[(int)round(((float)width / (float)new_width) * j + width * i)];
		}
	}
}

void small_height(unsigned int *r, unsigned int *g, unsigned int *b, int new_width, int height, int new_height, unsigned int *yr, unsigned int *yg, unsigned int *yb) {
	for (int i = 0; i < new_height; i++) {
		for (int j = 0; j < new_width; j++) {
			yr[new_width * i + j] = r[(int)round(((float)height / (float)new_height) * i) * new_width + j];
			yg[new_width * i + j] = g[(int)round(((float)height / (float)new_height) * i) * new_width + j];
			yb[new_width * i + j] = b[(int)round(((float)height / (float)new_height) * i) * new_width + j];
		}
	}
}

void writing(px_arr young, int new_height, ofstream &os, int new_width) {
	for (int i = 0; i < new_height; i++) {
		for (int j = 0; j < new_width; j++) {
			os.write(reinterpret_cast<char*>(&young.b[new_width * i + j]), sizeof(char));
			os.write(reinterpret_cast<char*>(&young.g[new_width * i + j]), sizeof(char));
			os.write(reinterpret_cast<char*>(&young.r[new_width * i + j]), sizeof(char));
		}
	}

}


int main(int argc, char **argv)
{
	setlocale(LC_CTYPE, "rus");
	int size = 0, pixels_adress = 0, width = 0, height = 0;
	short int bits_per_pixel = 0;

	ifstream file("nature.bmp", ios::in | ios::binary);

	// ѕереходим на 2 байт
	file.seekg(2, ios::beg);

	// —читываем размер файла
	file.read((char*)&size, sizeof(int));
	std::cout << "Size: " << size << endl;

	// ѕереходим на 10 байт
	file.seekg(10, ios::beg);

	// —читываем адрес, где лежит информаци€ о пиксел€х
	file.read((char*)&pixels_adress, sizeof(int));
	std::cout << "pixels_adress: " << pixels_adress << endl;

	// ѕереходим на 18 байт
	file.seekg(18, ios::beg);

	//—читываем ширину картинки
	file.read((char*)&width, sizeof(int));
	std::cout << "width: " << width << endl;

	// ѕереходим на 22 байт
	file.seekg(22, ios::beg);

	//—читываем высоту картинки
	file.read((char*)&height, sizeof(int));
	std::cout << "height: " << height << endl;

	// ѕереходим на 28 байт
	file.seekg(28, ios::beg);

	//—читываем количество бит на пиксель
	file.read((char*)&bits_per_pixel, sizeof(short int));
	std::cout << "bits_per_pixel: " << bits_per_pixel << endl;

	//двигаемс€ в зону цветов пикселей
	file.seekg(pixels_adress, ios::beg);

	int new_width, new_height;
	std::cout << "нова€ ширина изображени€ в пиксел€х (меньше текушей и делитс€ на 4)" << endl;
	std::cin >> new_width;
	std::cout << endl;

	std::cout << "нова€ высота изображени€ в пиксел€х" << endl;
	std::cin >> new_height;
	std::cout << endl;


	std::ofstream os("temp_0.bmp", std::ios::binary);
	unsigned char signature[2] = { 'B', 'M' };
	unsigned int fileSize = 14 + 40 + new_width * new_height * 3;
	unsigned int reserved = 0;
	unsigned int offset = 14 + 40;
	unsigned int headerSize = 40;
	unsigned int dimensions1 = new_width;
	unsigned int dimensions2 = new_height;
	unsigned short colorPlanes = 1;
	unsigned short bpp = 24;
	unsigned int compression = 0;
	unsigned int imgSize = new_width * new_height * 3;
	unsigned int resolution[2] = { 2795, 2795 };
	unsigned int pltColors = 0;
	unsigned int impColors = 0;
	os.write(reinterpret_cast<char*>(signature), sizeof(signature));
	os.write(reinterpret_cast<char*>(&fileSize), sizeof(fileSize));
	os.write(reinterpret_cast<char*>(&reserved), sizeof(reserved));
	os.write(reinterpret_cast<char*>(&offset), sizeof(offset));
	os.write(reinterpret_cast<char*>(&headerSize), sizeof(headerSize));
	os.write(reinterpret_cast<char*>(&dimensions1), sizeof(dimensions1));
	os.write(reinterpret_cast<char*>(&dimensions2), sizeof(dimensions2));
	os.write(reinterpret_cast<char*>(&colorPlanes), sizeof(colorPlanes));
	os.write(reinterpret_cast<char*>(&bpp), sizeof(bpp));
	os.write(reinterpret_cast<char*>(&compression), sizeof(compression));
	os.write(reinterpret_cast<char*>(&imgSize), sizeof(imgSize));
	os.write(reinterpret_cast<char*>(resolution), sizeof(resolution));
	os.write(reinterpret_cast<char*>(&pltColors), sizeof(pltColors));
	os.write(reinterpret_cast<char*>(&impColors), sizeof(impColors));

	px_arr old, young_w, young_wh;
	young_w.r = new unsigned int[height * new_width];
	young_w.g = new unsigned int[height * new_width];
	young_w.b = new unsigned int[height * new_width];
	young_wh.r = new unsigned int[new_height * new_width];
	young_wh.g = new unsigned int[new_height * new_width];
	young_wh.b = new unsigned int[new_height * new_width];
	old = reading(width, height, file);
	small_width(old.r, old.g, old.b, width, height, new_width, young_w.r, young_w.g, young_w.b);

	small_height(young_w.r, young_w.g, young_w.b, new_width, height, new_height, young_wh.r, young_wh.g, young_wh.b);
	writing(young_wh, new_height, os, new_width);

	os.close();

	return 0;
}