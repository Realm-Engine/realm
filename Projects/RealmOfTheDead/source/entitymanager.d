module realmofthedead.entitymanager;


public
{
	import realmofthedead.gameentity;
	import realmofthedead.player;
	import realm.engine.core;
	import realmofthedead.gun;
}

private
{
	import realm.engine.ecs;
}
class EntityManager
{
	mixin EntityRegistry!(Player,Gun);	

}
