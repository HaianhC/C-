#include <iostream>

using namespace std;

bool songuyento(int a)

{

    for (int i = 2; i <= a / 2; i++)

    {

        if (a % i == 0)
            return false;
    }

    return true;
}

bool KTSBlum(int a)

{

    if (songuyento(a) == true)
        return false;

    for (int i = 2; i <= a / 2; i++)

    {

        if (a % i == 0)

        {

            if (songuyento(i) == true)

            {

                if (songuyento(a / i) == true)
                    return true;

                else
                    return false;
            }
        }
    }
}

int main()

{

    int N;

    cout << "nhap so nguyen duong N: ";

    cin >> N;

    cout << "cac so Blum la: " << endl;

    for (int i = 2; i <= N; i++)

    {

        if (KTSBlum(i) == true)

        {

            cout << i << endl;

            for (int j = 2; j <= i / 2; j++)

            {

                if (i % j == 0)

                {

                    if (songuyento(j) == true)

                        if (songuyento(i / j) == true)

                            cout << i << "=" << j << "*" << i / j << endl;
                }
            }
        }
    }
}