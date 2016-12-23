using UnityEngine;
using System.Collections;
using System.Collections.Generic; 

public class DistanceField2D : MonoBehaviour {
	//public Texture2D tx = null ;

	class Particule
	{
		float x,y ;
		float vx,vy ;

		public Particule(){
			x=Random.value ;
			y=Random.value ;
			vx=Random.value/200 ;
			vy=Random.value/200 ; 
		}

		public void update(){
			if (x > 1.0 || x < 0.0) {
				vx = -vx;
				x+=vx;
			}
			if (y > 1.0 || y < 0.0) {
				vy = -vy;
				y+=vy;
			}

			x += vx;
			y += vy;
		}

		public byte getX(){ return (byte)(x*255); }
		public byte getY(){ return (byte)(y*255); }
	}

	List<Particule> particules ;

	// Use this for initialization
	void Start () {
		Texture2D tx=GetComponent<Renderer>().material.GetTexture("_Positions") as Texture2D;

		particules = new List<Particule> () ;
		for (int i=0; i<tx.width; i++) {
			particules.Add(new Particule());
		}
	}
	
	// Update is called once per frame
	void Update () {
		Texture2D tx=GetComponent<Renderer>().material.GetTexture("_Positions") as Texture2D;
		if (!tx)
			return; 

		int i = 0;
		foreach (Particule p in particules) {
			p.update() ;
			if (i < tx.width) {
				tx.SetPixel (i, 0, new Color32 (p.getX(), p.getY (), (byte)(i*8), 255)) ;
			} 
			i+=1 ;
		}
		tx.Apply();
	}
}
