defmodule Cambiatus.Repo.Migrations.CostaRicaFill do
  use Ecto.Migration

  alias Cambiatus.{
    Repo,
    Kyc.Country,
    Kyc.State,
    Kyc.City,
    Kyc.Neighborhood
  }

  def up do
    {:ok, costa_rica} = Repo.insert(%Country{name: "Costa Rica"})

    {:ok, san_jose} = Repo.insert(%State{name: "San José", country: costa_rica})
    {:ok, alajuela} = Repo.insert(%State{name: "Alajuela", country: costa_rica})
    {:ok, cartago} = Repo.insert(%State{name: "Cartago", country: costa_rica})
    {:ok, heredia} = Repo.insert(%State{name: "Heredia", country: costa_rica})
    {:ok, guanacaste} = Repo.insert(%State{name: "Guanacaste", country: costa_rica})
    {:ok, puntarenas} = Repo.insert(%State{name: "Puntarenas", country: costa_rica})
    {:ok, limon} = Repo.insert(%State{name: "Limón", country: costa_rica})

    san_jose_cities(san_jose)
    alajuela_cities(alajuela)
    cartago_cities(cartago)
    heredia_cities(heredia)
    guanacaste_cities(guanacaste)
    puntarenas_cities(puntarenas)
    limon_cities(limon)
  end

  def down do
    Repo.delete_all(Neighborhood)
    Repo.delete_all(City)
    Repo.delete_all(State)
    Repo.delete_all(Country)
  end

  defp san_jose_cities(san_jose) do
    {:ok, _} =
      Repo.insert(%City{
        name: "San José",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "Carmen"},
          %Neighborhood{name: "Merced"},
          %Neighborhood{name: "Hospital"},
          %Neighborhood{name: "Catedral"},
          %Neighborhood{name: "Zapote"},
          %Neighborhood{name: "San Francisco de Dos Ríos"},
          %Neighborhood{name: "Uruca"},
          %Neighborhood{name: "Mata Redonda"},
          %Neighborhood{name: "Pavas"},
          %Neighborhood{name: "Hatillo"},
          %Neighborhood{name: "San Sebastián"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Escazú",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "Escazú"},
          %Neighborhood{name: "San Antonio"},
          %Neighborhood{name: "San Rafael"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Desamparados",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "Desamparados"},
          %Neighborhood{name: "San Miguel"},
          %Neighborhood{name: "San Juan de Dios"},
          %Neighborhood{name: "San Rafael Arriba"},
          %Neighborhood{name: "San Antonio"},
          %Neighborhood{name: "Frailes"},
          %Neighborhood{name: "Patarrá"},
          %Neighborhood{name: "San Cristóbal"},
          %Neighborhood{name: "Rosario"},
          %Neighborhood{name: "Damas"},
          %Neighborhood{name: "San Rafael Abajo"},
          %Neighborhood{name: "Gravilias"},
          %Neighborhood{name: "Los Guido"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Puriscal",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "Santiago"},
          %Neighborhood{name: "Mercedes Sur"},
          %Neighborhood{name: "Barbacoas"},
          %Neighborhood{name: "Grifo Alto"},
          %Neighborhood{name: "San Rafael"},
          %Neighborhood{name: "Candelarita"},
          %Neighborhood{name: "Desamparaditos"},
          %Neighborhood{name: "San Antonio"},
          %Neighborhood{name: "Chires"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Tarrazú",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "San Marcos"},
          %Neighborhood{name: "San Lorenzo"},
          %Neighborhood{name: "San Carlos"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Aserrí",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "Aserrí"},
          %Neighborhood{name: "Tarbaca"},
          %Neighborhood{name: "Vuelta de Jorco"},
          %Neighborhood{name: "San Gabriel"},
          %Neighborhood{name: "Legua"},
          %Neighborhood{name: "Monterrey"},
          %Neighborhood{name: "Salitrillos"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Mora",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "Colón"},
          %Neighborhood{name: "Guayabo"},
          %Neighborhood{name: "Tabarcia"},
          %Neighborhood{name: "Piedras Negras"},
          %Neighborhood{name: "Picagres"},
          %Neighborhood{name: "Jaris"},
          %Neighborhood{name: "Quitirrisí"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Goicoechea",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "Guadalupe"},
          %Neighborhood{name: "San Francisco"},
          %Neighborhood{name: "Calle Blancos"},
          %Neighborhood{name: "Mata de Plátano"},
          %Neighborhood{name: "Ipís"},
          %Neighborhood{name: "Rancho Redondo"},
          %Neighborhood{name: "Purral"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Santa Ana",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "Santa Ana"},
          %Neighborhood{name: "Salitral"},
          %Neighborhood{name: "Pozos"},
          %Neighborhood{name: "Uruca"},
          %Neighborhood{name: "Piedades"},
          %Neighborhood{name: "Brasil"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Alajuelita",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "Alajuelita"},
          %Neighborhood{name: "San Josecito"},
          %Neighborhood{name: "San Antonio"},
          %Neighborhood{name: "Concepción"},
          %Neighborhood{name: "San Felipe"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Vásquez de Coronado",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "San Isidro"},
          %Neighborhood{name: "San Rafael"},
          %Neighborhood{name: "Dulce Nombre de Jesús"},
          %Neighborhood{name: "Patalillo"},
          %Neighborhood{name: "Cascajal"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Acosta",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "San Ignacio"},
          %Neighborhood{name: "Guaitil"},
          %Neighborhood{name: "Palmichal"},
          %Neighborhood{name: "Cangrejal"},
          %Neighborhood{name: "Sabanillas"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Tibás",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "San Juan"},
          %Neighborhood{name: "Cinco Esquinas"},
          %Neighborhood{name: "Anselmo Llorente"},
          %Neighborhood{name: "León XIII"},
          %Neighborhood{name: "Colima"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Moravia",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "San Vicente"},
          %Neighborhood{name: "San Jerónimo"},
          %Neighborhood{name: "La Trinidad"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Montes de Oca",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "San Pedro"},
          %Neighborhood{name: "Sabanilla"},
          %Neighborhood{name: "Mercedes"},
          %Neighborhood{name: "San Rafael"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Turrubares",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "San Pablo"},
          %Neighborhood{name: "San Pedro"},
          %Neighborhood{name: "San Juan de Mata"},
          %Neighborhood{name: "San Luis"},
          %Neighborhood{name: "Carara"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Dota",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "Santa María"},
          %Neighborhood{name: "Jardín"},
          %Neighborhood{name: "Copey"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Curridabat",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "Curridabat"},
          %Neighborhood{name: "Granadilla"},
          %Neighborhood{name: "Sánchez"},
          %Neighborhood{name: "Tirrases"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "Pérez Zeledón",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "San Isidro de El General"},
          %Neighborhood{name: "El General"},
          %Neighborhood{name: "Daniel Flores"},
          %Neighborhood{name: "Rivas"},
          %Neighborhood{name: "San Pedro"},
          %Neighborhood{name: "Platanares"},
          %Neighborhood{name: "Pejibaye"},
          %Neighborhood{name: "Cajón"},
          %Neighborhood{name: "Barú"},
          %Neighborhood{name: "Río Nuevo"},
          %Neighborhood{name: "Páramo"},
          %Neighborhood{name: "La Amistad"}
        ]
      })

    {:ok, _} =
      Repo.insert(%City{
        name: "León Cortés Castro",
        state: san_jose,
        neighborhoods: [
          %Neighborhood{name: "San Pablo"},
          %Neighborhood{name: "San Andrés"},
          %Neighborhood{name: "Llano Bonito"},
          %Neighborhood{name: "San Isidro"},
          %Neighborhood{name: "Santa Cruz"},
          %Neighborhood{name: "San Antonio"}
        ]
      })
  end

  defp alajuela_cities(alajuela) do
    Repo.insert(%City{
      name: "Alajuela",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Alajuela"},
        %Neighborhood{name: "San José"},
        %Neighborhood{name: "Carrizal"},
        %Neighborhood{name: "San Antonio"},
        %Neighborhood{name: "Guácima"},
        %Neighborhood{name: "San Isidro"},
        %Neighborhood{name: "Sabanilla"},
        %Neighborhood{name: "San Rafael"},
        %Neighborhood{name: "Río Segundo"},
        %Neighborhood{name: "Desamparados"},
        %Neighborhood{name: "Turrúcares"},
        %Neighborhood{name: "Tambor"},
        %Neighborhood{name: "Garita"},
        %Neighborhood{name: "Sarapiquí"}
      ]
    })

    Repo.insert(%City{
      name: "San Ramón",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "San Ramón"},
        %Neighborhood{name: "Santiago"},
        %Neighborhood{name: "San Juan"},
        %Neighborhood{name: "Piedades Norte"},
        %Neighborhood{name: "Piedades Sur"},
        %Neighborhood{name: "San Rafael"},
        %Neighborhood{name: "San Isidro"},
        %Neighborhood{name: "Los Ángeles"},
        %Neighborhood{name: "Alfaro"},
        %Neighborhood{name: "Volio"},
        %Neighborhood{name: "Concepción"},
        %Neighborhood{name: "Zapotal"},
        %Neighborhood{name: "Peñas Blancas"},
        %Neighborhood{name: "San Lorenzo"}
      ]
    })

    Repo.insert(%City{
      name: "Grecia",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Grecia"},
        %Neighborhood{name: "San Isidro"},
        %Neighborhood{name: "San José"},
        %Neighborhood{name: "San Roque"},
        %Neighborhood{name: "Tacares"},
        %Neighborhood{name: "Puente de Piedra"},
        %Neighborhood{name: "Bolívar"}
      ]
    })

    Repo.insert(%City{
      name: "San Mateo",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "San Mateo"},
        %Neighborhood{name: "Desmonte"},
        %Neighborhood{name: "Jesús María"},
        %Neighborhood{name: "Labrador"}
      ]
    })

    Repo.insert(%City{
      name: "Atenas",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Atenas"},
        %Neighborhood{name: "Jesús"},
        %Neighborhood{name: "Mercedes"},
        %Neighborhood{name: "San Isidro"},
        %Neighborhood{name: "Concepción"},
        %Neighborhood{name: "San José"},
        %Neighborhood{name: "Santa Eulalia"},
        %Neighborhood{name: "Escobal"}
      ]
    })

    Repo.insert(%City{
      name: "Naranjo",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Naranjo"},
        %Neighborhood{name: "San Miguel"},
        %Neighborhood{name: "San José"},
        %Neighborhood{name: "Cirrí Sur"},
        %Neighborhood{name: "San Jerónimo"},
        %Neighborhood{name: "San Juan"},
        %Neighborhood{name: "El Rosario"},
        %Neighborhood{name: "Palmitos"}
      ]
    })

    Repo.insert(%City{
      name: "Palmares",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Palmares"},
        %Neighborhood{name: "Zaragoza"},
        %Neighborhood{name: "Buenos Aires"},
        %Neighborhood{name: "Santiago"},
        %Neighborhood{name: "Candelaria"},
        %Neighborhood{name: "Esquipulas"},
        %Neighborhood{name: "La Granja"}
      ]
    })

    Repo.insert(%City{
      name: "Poás",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "San Pedro"},
        %Neighborhood{name: "San Juan"},
        %Neighborhood{name: "San Rafael"},
        %Neighborhood{name: "Carrillos"},
        %Neighborhood{name: "Sabana Redonda"}
      ]
    })

    Repo.insert(%City{
      name: "Orotina",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Orotina"},
        %Neighborhood{name: "El Mastate"},
        %Neighborhood{name: "Hacienda Vieja"},
        %Neighborhood{name: "Coyolar"},
        %Neighborhood{name: "La Ceiba"}
      ]
    })

    Repo.insert(%City{
      name: "San Carlos",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Quesada"},
        %Neighborhood{name: "Florencia"},
        %Neighborhood{name: "Buenavista"},
        %Neighborhood{name: "Aguas Zarcas"},
        %Neighborhood{name: "Venecia"},
        %Neighborhood{name: "Pital"},
        %Neighborhood{name: "La Fortuna"},
        %Neighborhood{name: "La Tigra"},
        %Neighborhood{name: "La Palmera"},
        %Neighborhood{name: "Venado"},
        %Neighborhood{name: "Cutris"},
        %Neighborhood{name: "Monterrey"},
        %Neighborhood{name: "Pocosol"}
      ]
    })

    Repo.insert(%City{
      name: "Zarcero",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Zarcero"},
        %Neighborhood{name: "Laguna"},
        %Neighborhood{name: "Tapezco"},
        %Neighborhood{name: "Guadalupe"},
        %Neighborhood{name: "Palmira"},
        %Neighborhood{name: "Zapote"},
        %Neighborhood{name: "Brisas"}
      ]
    })

    Repo.insert(%City{
      name: "Sarchí",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Sarchí Norte"},
        %Neighborhood{name: "Sarchí Sur"},
        %Neighborhood{name: "Toro Amarillo"},
        %Neighborhood{name: "San Pedro"},
        %Neighborhood{name: "Rodríguez"}
      ]
    })

    Repo.insert(%City{
      name: "Upala",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Upala"},
        %Neighborhood{name: "Aguas Claras"},
        %Neighborhood{name: "San José (Pizote)"},
        %Neighborhood{name: "Bijagua"},
        %Neighborhood{name: "Delicias"},
        %Neighborhood{name: "Dos Ríos"},
        %Neighborhood{name: "Yolillal"},
        %Neighborhood{name: "Canalete"}
      ]
    })

    Repo.insert(%City{
      name: "Los Chiles",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Los Chiles"},
        %Neighborhood{name: "Caño Negro"},
        %Neighborhood{name: "El Amparo"},
        %Neighborhood{name: "San Jorge"}
      ]
    })

    Repo.insert(%City{
      name: "Guatuso",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "San Rafael"},
        %Neighborhood{name: "Buenavista"},
        %Neighborhood{name: "Cote"},
        %Neighborhood{name: "Katira"}
      ]
    })

    Repo.insert(%City{
      name: "Río Cuarto",
      state: alajuela,
      neighborhoods: [
        %Neighborhood{name: "Río Cuarto"},
        %Neighborhood{name: "Santa Rita"},
        %Neighborhood{name: "Santa Isabel"}
      ]
    })
  end

  defp cartago_cities(cartago) do
    Repo.insert(%City{
      name: "Cartago",
      state: cartago,
      neighborhoods: [
        %Neighborhood{name: "Oriental"},
        %Neighborhood{name: "Occidental"},
        %Neighborhood{name: "Carmen"},
        %Neighborhood{name: "San Nicolás"},
        %Neighborhood{name: "Aguacaliente (San Francisco)"},
        %Neighborhood{name: "Guadalupe (Arenilla)"},
        %Neighborhood{name: "Corralillo"},
        %Neighborhood{name: "Tierra Blanca"},
        %Neighborhood{name: "Dulce Nombre"},
        %Neighborhood{name: "Llano Grande"},
        %Neighborhood{name: "Quebradilla"}
      ]
    })

    Repo.insert(%City{
      name: "Paraíso",
      state: cartago,
      neighborhoods: [
        %Neighborhood{name: "Paraíso"},
        %Neighborhood{name: "Santiago"},
        %Neighborhood{name: "Orosi"},
        %Neighborhood{name: "Cachí"},
        %Neighborhood{name: "Llanos de Santa Lucía"}
      ]
    })

    Repo.insert(%City{
      name: "La Unión",
      state: cartago,
      neighborhoods: [
        %Neighborhood{name: "Tres Ríos"},
        %Neighborhood{name: "San Diego"},
        %Neighborhood{name: "San Juan"},
        %Neighborhood{name: "San Rafael"},
        %Neighborhood{name: "Concepción"},
        %Neighborhood{name: "Dulce Nombre"},
        %Neighborhood{name: "San Ramón"},
        %Neighborhood{name: "Río Azul"}
      ]
    })

    Repo.insert(%City{
      name: "Jiménez",
      state: cartago,
      neighborhoods: [
        %Neighborhood{name: "Juan Viñas"},
        %Neighborhood{name: "Tucurrique"},
        %Neighborhood{name: "Pejibaye"}
      ]
    })

    Repo.insert(%City{
      name: "Turrialba",
      state: cartago,
      neighborhoods: [
        %Neighborhood{name: "Turrialba"},
        %Neighborhood{name: "La Suiza"},
        %Neighborhood{name: "Peralta"},
        %Neighborhood{name: "Santa Cruz"},
        %Neighborhood{name: "Santa Teresita"},
        %Neighborhood{name: "Pavones"},
        %Neighborhood{name: "Tuis"},
        %Neighborhood{name: "Tayutic"},
        %Neighborhood{name: "Santa Rosa"},
        %Neighborhood{name: "Tres Equis"},
        %Neighborhood{name: "La Isabel"},
        %Neighborhood{name: "Chirripó"}
      ]
    })

    Repo.insert(%City{
      name: "Alvarado",
      state: cartago,
      neighborhoods: [
        %Neighborhood{name: "Pacayas"},
        %Neighborhood{name: "Cervantes"},
        %Neighborhood{name: "Capellades"}
      ]
    })

    Repo.insert(%City{
      name: "Oreamuno",
      state: cartago,
      neighborhoods: [
        %Neighborhood{name: "San Rafael"},
        %Neighborhood{name: "Cot"},
        %Neighborhood{name: "Potrero Cerrado"},
        %Neighborhood{name: "Cipreses"},
        %Neighborhood{name: "Santa Rosa"}
      ]
    })

    Repo.insert(%City{
      name: "El Guarco",
      state: cartago,
      neighborhoods: [
        %Neighborhood{name: "Tejar"},
        %Neighborhood{name: "San Isidro"},
        %Neighborhood{name: "Tobosi"},
        %Neighborhood{name: "Patio de Agua"}
      ]
    })
  end

  defp heredia_cities(heredia) do
    Repo.insert(%City{
      name: "Heredia",
      state: heredia,
      neighborhoods: [
        %Neighborhood{name: "Heredia"},
        %Neighborhood{name: "Mercedes"},
        %Neighborhood{name: "San Francisco"},
        %Neighborhood{name: "Ulloa"},
        %Neighborhood{name: "Varablanca"}
      ]
    })

    Repo.insert(%City{
      name: "Barva",
      state: heredia,
      neighborhoods: [
        %Neighborhood{name: "Barva"},
        %Neighborhood{name: "San Pedro"},
        %Neighborhood{name: "San Pablo"},
        %Neighborhood{name: "San Roque"},
        %Neighborhood{name: "Santa Lucía"},
        %Neighborhood{name: "San José de la Montaña"}
      ]
    })

    Repo.insert(%City{
      name: "Santo Domingo",
      state: heredia,
      neighborhoods: [
        %Neighborhood{name: "Santo Domingo"},
        %Neighborhood{name: "San Vicente"},
        %Neighborhood{name: "San Miguel"},
        %Neighborhood{name: "Paracito"},
        %Neighborhood{name: "Santo Tomás"},
        %Neighborhood{name: "Santa Rosa"},
        %Neighborhood{name: "Tures"},
        %Neighborhood{name: "Pará"}
      ]
    })

    Repo.insert(%City{
      name: "Santa Bárbara",
      state: heredia,
      neighborhoods: [
        %Neighborhood{name: "Santa Bárbara"},
        %Neighborhood{name: "San Pedro"},
        %Neighborhood{name: "San Juan"},
        %Neighborhood{name: "Jesús"},
        %Neighborhood{name: "Santo Domingo"},
        %Neighborhood{name: "Purabá"}
      ]
    })

    Repo.insert(%City{
      name: "San Rafael",
      state: heredia,
      neighborhoods: [
        %Neighborhood{name: "San Rafael"},
        %Neighborhood{name: "San Josecito"},
        %Neighborhood{name: "Santiago"},
        %Neighborhood{name: "Ángeles"},
        %Neighborhood{name: "Concepción"}
      ]
    })

    Repo.insert(%City{
      name: "San Isidro",
      state: heredia,
      neighborhoods: [
        %Neighborhood{name: "San Isidro"},
        %Neighborhood{name: "San José"},
        %Neighborhood{name: "Concepción"},
        %Neighborhood{name: "San Francisco"}
      ]
    })

    Repo.insert(%City{
      name: "Belén",
      state: heredia,
      neighborhoods: [
        %Neighborhood{name: "San Antonio"},
        %Neighborhood{name: "Rivera"},
        %Neighborhood{name: "La Asunción"}
      ]
    })

    Repo.insert(%City{
      name: "Flores",
      state: heredia,
      neighborhoods: [
        %Neighborhood{name: "San Joaquín"},
        %Neighborhood{name: "Barrantes"},
        %Neighborhood{name: "Llorente"}
      ]
    })

    Repo.insert(%City{
      name: "San Pablo",
      state: heredia,
      neighborhoods: [
        %Neighborhood{name: "San Pablo"},
        %Neighborhood{name: "Rincón de Sabanilla"}
      ]
    })

    Repo.insert(%City{
      name: "Sarapiquí",
      state: heredia,
      neighborhoods: [
        %Neighborhood{name: "Puerto Viejo"},
        %Neighborhood{name: "La Virgen"},
        %Neighborhood{name: "Horquetas"},
        %Neighborhood{name: "Llanuras del Gaspar"},
        %Neighborhood{name: "Cureña"}
      ]
    })
  end

  defp guanacaste_cities(guanacaste) do
    Repo.insert(%City{
      name: "Liberia",
      state: guanacaste,
      neighborhoods: [
        %Neighborhood{name: "Liberia"},
        %Neighborhood{name: "Cañas Dulces"},
        %Neighborhood{name: "Mayorga"},
        %Neighborhood{name: "Nacascolo"},
        %Neighborhood{name: "Curubandé"}
      ]
    })

    Repo.insert(%City{
      name: "Nicoya",
      state: guanacaste,
      neighborhoods: [
        %Neighborhood{name: "Nicoya"},
        %Neighborhood{name: "Mansión"},
        %Neighborhood{name: "San Antonio"},
        %Neighborhood{name: "Quebrada Honda"},
        %Neighborhood{name: "Sámara"},
        %Neighborhood{name: "Nosara"},
        %Neighborhood{name: "Belén de Nosarita"}
      ]
    })

    Repo.insert(%City{
      name: "Santa Cruz",
      state: guanacaste,
      neighborhoods: [
        %Neighborhood{name: "Santa Cruz"},
        %Neighborhood{name: "Bolsón"},
        %Neighborhood{name: "Veintisiete de Abril"},
        %Neighborhood{name: "Tempate"},
        %Neighborhood{name: "Cartagena"},
        %Neighborhood{name: "Cuajiniquil"},
        %Neighborhood{name: "Diriá"},
        %Neighborhood{name: "Cabo Velas"},
        %Neighborhood{name: "Tamarindo"}
      ]
    })

    Repo.insert(%City{
      name: "Bagaces",
      state: guanacaste,
      neighborhoods: [
        %Neighborhood{name: "Bagaces"},
        %Neighborhood{name: "Fortuna"},
        %Neighborhood{name: "Mogote"},
        %Neighborhood{name: "Río Naranjo"}
      ]
    })

    Repo.insert(%City{
      name: "Carrillo",
      state: guanacaste,
      neighborhoods: [
        %Neighborhood{name: "Filadelfia"},
        %Neighborhood{name: "Palmira"},
        %Neighborhood{name: "Sardinal"},
        %Neighborhood{name: "Belén"}
      ]
    })

    Repo.insert(%City{
      name: "Cañas",
      state: guanacaste,
      neighborhoods: [
        %Neighborhood{name: "Cañas"},
        %Neighborhood{name: "Palmira"},
        %Neighborhood{name: "San Miguel"},
        %Neighborhood{name: "Bebedero"},
        %Neighborhood{name: "Porozal"}
      ]
    })

    Repo.insert(%City{
      name: "Abangares",
      state: guanacaste,
      neighborhoods: [
        %Neighborhood{name: "Las Juntas"},
        %Neighborhood{name: "Sierra"},
        %Neighborhood{name: "San Juan"},
        %Neighborhood{name: "Colorado"}
      ]
    })

    Repo.insert(%City{
      name: "Tilarán",
      state: guanacaste,
      neighborhoods: [
        %Neighborhood{name: "Tilarán"},
        %Neighborhood{name: "Quebrada Grande"},
        %Neighborhood{name: "Tronadora"},
        %Neighborhood{name: "Santa Rosa"},
        %Neighborhood{name: "Líbano"},
        %Neighborhood{name: "Tierras Morenas"},
        %Neighborhood{name: "Arenal"},
        %Neighborhood{name: "Cabeceras"}
      ]
    })

    Repo.insert(%City{
      name: "Nandayure",
      state: guanacaste,
      neighborhoods: [
        %Neighborhood{name: "Carmona"},
        %Neighborhood{name: "Santa Rita"},
        %Neighborhood{name: "Zapotal"},
        %Neighborhood{name: "San Pablo"},
        %Neighborhood{name: "Porvenir"},
        %Neighborhood{name: "Bejuco"}
      ]
    })

    Repo.insert(%City{
      name: "La Cruz",
      state: guanacaste,
      neighborhoods: [
        %Neighborhood{name: "La Cruz"},
        %Neighborhood{name: "Santa Cecilia"},
        %Neighborhood{name: "Garita"},
        %Neighborhood{name: "Santa Elena"}
      ]
    })

    Repo.insert(%City{
      name: "Hojancha",
      state: guanacaste,
      neighborhoods: [
        %Neighborhood{name: "Hojancha"},
        %Neighborhood{name: "Monte Romo"},
        %Neighborhood{name: "Puerto Carrillo"},
        %Neighborhood{name: "Huacas"},
        %Neighborhood{name: "Matambú"}
      ]
    })
  end

  defp puntarenas_cities(puntarenas) do
    Repo.insert(%City{
      name: "Puntarenas",
      state: puntarenas,
      neighborhoods: [
        %Neighborhood{name: "Puntarenas"},
        %Neighborhood{name: "Pitahaya"},
        %Neighborhood{name: "Chomes"},
        %Neighborhood{name: "Lepanto"},
        %Neighborhood{name: "Paquera"},
        %Neighborhood{name: "Manzanillo"},
        %Neighborhood{name: "Guacimal"},
        %Neighborhood{name: "Barranca"},
        %Neighborhood{name: "Monte Verde"},
        %Neighborhood{name: "Isla del Coco"},
        %Neighborhood{name: "Cóbano"},
        %Neighborhood{name: "Chacarita"},
        %Neighborhood{name: "Chira"},
        %Neighborhood{name: "Acapulco"},
        %Neighborhood{name: "El Roble"},
        %Neighborhood{name: "Arancibia"}
      ]
    })

    Repo.insert(%City{
      name: "Esparza",
      state: puntarenas,
      neighborhoods: [
        %Neighborhood{name: "Espíritu Santo"},
        %Neighborhood{name: "San Juan Grande"},
        %Neighborhood{name: "Macacona"},
        %Neighborhood{name: "San Rafael"},
        %Neighborhood{name: "San Jerónimo"},
        %Neighborhood{name: "Caldera"}
      ]
    })

    Repo.insert(%City{
      name: "Buenos Aires",
      state: puntarenas,
      neighborhoods: [
        %Neighborhood{name: "Buenos Aires"},
        %Neighborhood{name: "Volcán"},
        %Neighborhood{name: "Potrero Grande"},
        %Neighborhood{name: "Boruca"},
        %Neighborhood{name: "Pilas"},
        %Neighborhood{name: "Colinas"},
        %Neighborhood{name: "Chánguena"},
        %Neighborhood{name: "Biolley"},
        %Neighborhood{name: "Brunka"}
      ]
    })

    Repo.insert(%City{
      name: "Montes de Oro",
      state: puntarenas,
      neighborhoods: [
        %Neighborhood{name: "Miramar"},
        %Neighborhood{name: "La Unión"},
        %Neighborhood{name: "San Isidro"}
      ]
    })

    Repo.insert(%City{
      name: "Osa",
      state: puntarenas,
      neighborhoods: [
        %Neighborhood{name: "Puerto Cortés"},
        %Neighborhood{name: "Palmar"},
        %Neighborhood{name: "Sierpe"},
        %Neighborhood{name: "Bahía Ballena"},
        %Neighborhood{name: "Piedras Blancas"},
        %Neighborhood{name: "Bahía Drake"}
      ]
    })

    Repo.insert(%City{
      name: "Quepos",
      state: puntarenas,
      neighborhoods: [
        %Neighborhood{name: "Quepos"},
        %Neighborhood{name: "Savegre"},
        %Neighborhood{name: "Naranjito"}
      ]
    })

    Repo.insert(%City{
      name: "Golfito",
      state: puntarenas,
      neighborhoods: [
        %Neighborhood{name: "Golfito"},
        %Neighborhood{name: "Puerto Jiménez"},
        %Neighborhood{name: "Guaycará"},
        %Neighborhood{name: "Pavón"}
      ]
    })

    Repo.insert(%City{
      name: "Coto Brus",
      state: puntarenas,
      neighborhoods: [
        %Neighborhood{name: "San Vito"},
        %Neighborhood{name: "Sabalito"},
        %Neighborhood{name: "Aguabuena"},
        %Neighborhood{name: "Limoncito"},
        %Neighborhood{name: "Pittier"},
        %Neighborhood{name: "Gutiérrez Braun"}
      ]
    })

    Repo.insert(%City{
      name: "Parrita",
      state: puntarenas,
      neighborhoods: [%Neighborhood{name: "Parrita"}]
    })

    Repo.insert(%City{
      name: "Corredores",
      state: puntarenas,
      neighborhoods: [
        %Neighborhood{name: "Corredor"},
        %Neighborhood{name: "La Cuesta"},
        %Neighborhood{name: "Canoas"},
        %Neighborhood{name: "Laurel"}
      ]
    })

    Repo.insert(%City{
      name: "Garabito",
      state: puntarenas,
      neighborhoods: [%Neighborhood{name: "Jacó"}, %Neighborhood{name: "Tárcoles"}]
    })
  end

  defp limon_cities(limon) do
    Repo.insert(%City{
      name: "Limón",
      state: limon,
      neighborhoods: [
        %Neighborhood{name: "Limón"},
        %Neighborhood{name: "Valle La Estrella"},
        %Neighborhood{name: "Río Blanco"},
        %Neighborhood{name: "Matama"}
      ]
    })

    Repo.insert(%City{
      name: "Pococí",
      state: limon,
      neighborhoods: [
        %Neighborhood{name: "Guápiles"},
        %Neighborhood{name: "Jiménez"},
        %Neighborhood{name: "La Rita"},
        %Neighborhood{name: "Roxana"},
        %Neighborhood{name: "Cariari"},
        %Neighborhood{name: "Colorado"},
        %Neighborhood{name: "La Colonia"}
      ]
    })

    Repo.insert(%City{
      name: "Siquirres",
      state: limon,
      neighborhoods: [
        %Neighborhood{name: "Siquirres"},
        %Neighborhood{name: "Pacuarito"},
        %Neighborhood{name: "Florida"},
        %Neighborhood{name: "Germania"},
        %Neighborhood{name: "Cairo"},
        %Neighborhood{name: "Alegría"},
        %Neighborhood{name: "Reventazón"}
      ]
    })

    Repo.insert(%City{
      name: "Talamanca",
      state: limon,
      neighborhoods: [
        %Neighborhood{name: "Bratsi"},
        %Neighborhood{name: "Sixaola"},
        %Neighborhood{name: "Cahuita"},
        %Neighborhood{name: "Telire"}
      ]
    })

    Repo.insert(%City{
      name: "Matina",
      state: limon,
      neighborhoods: [
        %Neighborhood{name: "Matina"},
        %Neighborhood{name: "Batán"},
        %Neighborhood{name: "Carrandi"}
      ]
    })

    Repo.insert(%City{
      name: "Guácimo",
      state: limon,
      neighborhoods: [
        %Neighborhood{name: "Guácimo"},
        %Neighborhood{name: "Mercedes"},
        %Neighborhood{name: "Pocora"},
        %Neighborhood{name: "Río Jiménez"},
        %Neighborhood{name: "Duacarí"}
      ]
    })
  end
end
