using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

public class FreeLifeBootstrap : MonoBehaviour
{
    GameObject player, car;
    CharacterController controller;
    Camera cam;
    Vector3 velocity;
    bool driving;
    float speed;
    int cash = 2500;
    string notice = "به فری‌لایف خوش آمدی";
    GUIStyle label;
    readonly Dictionary<string, int> jobs = new Dictionary<string, int>
    {
        {"راننده تاکسی",500},{"راننده اتوبوس",700},{"مکانیک",600},{"معلم",550},{"کشاورز",450}
    };

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    static void StartGame()
    {
        if (FindObjectOfType<FreeLifeBootstrap>() == null)
            new GameObject("FreeLifeGame").AddComponent<FreeLifeBootstrap>();
    }

    void Start()
    {
        Application.targetFrameRate = 60;
        BuildCity();
        BuildPlayer();
        BuildCar();
        cam = Camera.main;
        if (cam == null) { var c = new GameObject("Main Camera"); cam = c.AddComponent<Camera>(); c.tag = "MainCamera"; }
        cam.transform.position = new Vector3(0, 7, -10);
        cam.transform.rotation = Quaternion.Euler(25, 0, 0);
        label = new GUIStyle(GUI.skin.label) { fontSize = 22, normal = { textColor = Color.white } };
    }

    Material Mat(Color c) { var m = new Material(Shader.Find("Standard")); m.color = c; return m; }
    GameObject Cube(string n, Vector3 p, Vector3 s, Color c)
    {
        var o = GameObject.CreatePrimitive(PrimitiveType.Cube); o.name=n; o.transform.position=p; o.transform.localScale=s; o.GetComponent<Renderer>().material=Mat(c); return o;
    }
    void BuildCity()
    {
        Cube("Ground",new Vector3(0,-.3f,0),new Vector3(100,.5f,100),new Color(.25f,.48f,.25f));
        Cube("Main road",new Vector3(0,-.02f,0),new Vector3(12,.08f,100),new Color(.12f,.12f,.13f));
        for(int z=-45;z<50;z+=8) Cube("Road marking",new Vector3(0,.04f,z),new Vector3(.18f,.03f,3),Color.white);
        for(int x=-35;x<=35;x+=14)
        for(int z=-35;z<=35;z+=18)
        {
            if(Mathf.Abs(x)<10) continue;
            float h=Random.Range(5f,13f);
            Cube("City building",new Vector3(x,h/2,z),new Vector3(9,h,10),new Color(Random.Range(.35f,.7f),Random.Range(.35f,.65f),Random.Range(.35f,.65f)));
        }
        for(int i=0;i<12;i++)
        {
            float x=(i%2==0)?-8:8, z=-42+i*7;
            var trunk=GameObject.CreatePrimitive(PrimitiveType.Cylinder); trunk.transform.position=new Vector3(x,1,z); trunk.transform.localScale=new Vector3(.35f,1.5f,.35f); trunk.GetComponent<Renderer>().material=Mat(new Color(.35f,.2f,.1f));
            var crown=GameObject.CreatePrimitive(PrimitiveType.Sphere); crown.transform.position=new Vector3(x,3.2f,z); crown.transform.localScale=Vector3.one*2.4f; crown.GetComponent<Renderer>().material=Mat(new Color(.12f,.42f,.16f));
        }
    }
    void BuildPlayer()
    {
        player=GameObject.CreatePrimitive(PrimitiveType.Capsule); player.name="Player"; player.transform.position=new Vector3(-3,1,0);
        player.GetComponent<Renderer>().material=Mat(new Color(.1f,.45f,.85f));
        Destroy(player.GetComponent<Collider>());
        controller=player.AddComponent<CharacterController>();
    }
    void BuildCar()
    {
        car=GameObject.CreatePrimitive(PrimitiveType.Cube); car.name="FreeLife car"; car.transform.position=new Vector3(3,.65f,0); car.transform.localScale=new Vector3(2,1.1f,4);
        car.GetComponent<Renderer>().material=Mat(new Color(.75f,.12f,.1f));
        var col=car.GetComponent<BoxCollider>(); col.isTrigger=true;
        for(int side=-1;side<=1;side+=2) for(int z=-1;z<=1;z+=2)
        {
            var w=GameObject.CreatePrimitive(PrimitiveType.Cylinder); w.transform.SetParent(car.transform); w.transform.localPosition=new Vector3(side*.56f,-.35f,z*.34f); w.transform.localRotation=Quaternion.Euler(0,0,90); w.transform.localScale=new Vector3(.35f,.18f,.35f); w.GetComponent<Renderer>().material=Mat(Color.black);
        }
    }
    void Update()
    {
        if(!driving)
        {
            float h=Input.GetAxisRaw("Horizontal"), v=Input.GetAxisRaw("Vertical");
            Vector3 move=new Vector3(h,0,v).normalized;
            controller.Move(move*5f*Time.deltaTime);
            if(move.sqrMagnitude>.01f) player.transform.forward=move;
            if(Input.GetKeyDown(KeyCode.E) && Vector3.Distance(player.transform.position,car.transform.position)<4) { driving=true; notice="سوار خودرو شدی"; }
            if(Input.GetKeyDown(KeyCode.J)) CompleteJob();
        }
        else
        {
            float throttle=Input.GetAxisRaw("Vertical"), steer=Input.GetAxisRaw("Horizontal");
            speed=Mathf.MoveTowards(speed,throttle*12f,8f*Time.deltaTime);
            car.transform.Rotate(0,steer*speed*5f*Time.deltaTime,0);
            car.transform.position+=car.transform.forward*speed*Time.deltaTime;
            if(Input.GetKeyDown(KeyCode.E)){driving=false; player.transform.position=car.transform.position-car.transform.right*2.5f; notice="از خودرو پیاده شدی";}
        }
        if(cam && player)
        {
            Vector3 target=(driving?car.transform.position:player.transform.position)+new Vector3(0,7,-10);
            cam.transform.position=Vector3.Lerp(cam.transform.position,target,Time.deltaTime*5);
            cam.transform.LookAt(driving?car.transform:player.transform);
        }
    }
    void CompleteJob()
    {
        cash+=500; notice="ماموریت انجام شد: ۵۰۰ دلار دریافت کردی";
    }
    void OnGUI()
    {
        if(label==null) label=new GUIStyle(GUI.skin.label){fontSize=20,normal={textColor=Color.white}};
        GUI.Box(new Rect(12,12,300,88),"");
        GUI.Label(new Rect(24,18,280,30),"FreeLife RP  |  پول: $"+cash,label);
        GUI.Label(new Rect(24,52,280,35),notice,new GUIStyle(label){fontSize=16});
        float y=Screen.height-150;
        if(GUI.Button(new Rect(15,y,100,55),"تعامل / E")) { if(!driving && Vector3.Distance(player.transform.position,car.transform.position)<5){driving=true;notice="سوار خودرو شدی";} else if(driving){driving=false;player.transform.position=car.transform.position-car.transform.right*2.5f;} }
        if(GUI.Button(new Rect(125,y,100,55),"شغل / J")) CompleteJob();
        if(GUI.Button(new Rect(235,y,100,55),"کارها")) notice="شغل‌ها: تاکسی، اتوبوس، مکانیک، معلم، کشاورز";
        float cx=Screen.width-190, cy=Screen.height-230;
        if(GUI.RepeatButton(new Rect(cx,cy,65,60),"▲")) MoveTouch(Vector3.forward);
        if(GUI.RepeatButton(new Rect(cx,cy+125,65,60),"▼")) MoveTouch(Vector3.back);
        if(GUI.RepeatButton(new Rect(cx-70,cy+62,65,60),"◀")) MoveTouch(Vector3.left);
        if(GUI.RepeatButton(new Rect(cx+70,cy+62,65,60),"▶")) MoveTouch(Vector3.right);
    }
    void MoveTouch(Vector3 dir)
    {
        if(driving){car.transform.position+=car.transform.TransformDirection(dir)*7*Time.deltaTime;}
        else controller.Move(dir*4*Time.deltaTime);
    }
}
