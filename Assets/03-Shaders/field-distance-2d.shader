Shader "Custom/DistanceField2d" {
	Properties {
		_Level("Level", Range(0,2)) = 0.01
		_SkinSize("SkinSize", Range(0,0.5)) = 0.1
		_Positions ("Positions", 2D) = "white" {}
	    _ColorRamp ("Color Ramp", 2D) = "white" {}
	}
	
	SubShader {
	    Pass {
	    	CGPROGRAM
			#pragma vertex vert
			#pragma fragment fieldRenderer
			#pragma only_renderers d3d9
			#pragma target 3.0
			
			#include "UnityCG.cginc"
			
			float _Level ; 
			float _SkinSize ; 
			sampler2D _Positions ; 
			sampler2D _ColorRamp ;
			
			struct v2f {
			    float4  pos : SV_POSITION;
			    float4  uv : TEXCOORD0;
			};
			
			v2f vert (appdata_base v)
			{
			    v2f o;
			    o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			    o.uv = v.texcoord;
			    return o;
			}
			
			// Return the primitive position in xy an material/color in z. 
			// The positions are between -1 et 1.
			float2 getPrimitive(int i){
				float4 c=tex2D(_Positions, float2((1.0*i)/32,0)) ;
				c.xy = 2*(c.xy-float2(0.5,0.5)) ;
				return c.xy ; 
			}
			
			// Compute the potential field at pos for the sphere with radius h and position so
			float fieldAt(float2 pos, float2 so, float h)
			{
				float nr=distance(so, pos);
				if(nr < h){
					float t=pow(h,2)-pow(nr,2);
					return 315/(64*3.1416*pow(h,9))*pow(t,3) ;  
				}
				return 0 ;
			}
									
			// Return the field value in x component and the material color in y component
			// There is a maximum of 32 primitives. This value must be hardcoded. 
			float2 evaluateFieldAt(float2 pos)
			{	
				// Mettez ici le code qui évalue la valeur au point "pos".
				// Cette valeur est la somme des fonctions de potentiels.
				// produites par les différentes primitives. 
				float2 res = float2(0.0, 0.0);
				int i;
				// Les positions des fonctions de potentiels seront récupérés 
				// dans une texture à l'aide la fonction getPrimitive(int i)
				// Il y a 32 primitives dans la texture...donc i=[0,32].								

				for(i = 0; i < 32; i++) {
					float2 so = float2(getPrimitive(i));
					if(distance(so, pos) >= _SkinSize - 0.002 && distance(so, pos) <= _SkinSize + 0.002) {
						res.y = 1.;
					}
					res.x = res.x + fieldAt(pos, so, _SkinSize);
				}
				 
				return res ;
			}
			
		
			float4 fieldRenderer(v2f ver) : COLOR
			{
				// Récupère les coordonnée U/V et les transforme en position comprises entre (-1 et 1) 
				float2 p={(1.0-ver.uv[0]-0.5)*2.0, 1.0*(1.0-ver.uv[1]-0.5)*2.0} ;

				// Appelle la fonction d'évaluation au point P.
				float2 fieldValue=evaluateFieldAt(p) ;

				/// Mettre ici le code qui retourne des couleurs de pixel 
				/// différents suivant la valeur de la fonction de potentiel. 
				float4 col = float4(0.0,0.0,0.0,1.0);

				if(fieldValue.x > 0.) {
					col.r = sin(fieldValue.x / 100.);
					col.g = sin(fieldValue.x / 50.);
					col.b = sin(fieldValue.x / 25.);
				}
				if(fieldValue.y == 1.0) {
					col.r = col.g = col.b = 1.0;
				}

				return col;
			}
			ENDCG	
	    }
	}
	Fallback "VertexLit"
}
