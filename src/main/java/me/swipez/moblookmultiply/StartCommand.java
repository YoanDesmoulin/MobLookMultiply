package me.swipez.moblookmultiply;

import org.bukkit.Bukkit;
import org.bukkit.ChatColor;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;

public class StartCommand implements CommandExecutor {
    MobLookMultiply plugin;

    public StartCommand(MobLookMultiply plugin) {
        this.plugin = plugin;
    }

    @Override
    public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
        if (sender instanceof Player){
            if (sender.hasPermission("moblook.toggle")){
                Player p = (Player) sender;
                // Arguments
                if (args.length == 1){
                    if (args[0].equals("start")){
                        Bukkit.broadcastMessage(ChatColor.GREEN+"Mob look multiply challenge has started!");
                        MobLookMultiply.mobMultiplier.clear();
                        MobLookMultiply.duplicatedMobs.clear();
                        for (Player player : Bukkit.getOnlinePlayers()){
                            MobLookMultiply.mobMultiplier.put(player.getUniqueId(), 1);
                        }
                        MobLookMultiply.timer = MobLookMultiply.startingTimer;
                        MobLookMultiply.gamestarted = true;
                    }
                    if (args[0].equals("stop")) {
                        Bukkit.broadcastMessage(ChatColor.GREEN+"Mob look multiply challenge has ended!");
                        MobLookMultiply.gamestarted = false;
                        MobLookMultiply.duplicatedMobs.clear();
                    }

                }
                else {
                    p.sendMessage(ChatColor.RED+"/moblook <start/stop>");
                }
            }
            else {
                sender.sendMessage(ChatColor.RED+"You dont have the permission needed to run this command.");
            }
        }
        else {
            sender.sendMessage(ChatColor.RED+"This command is for players only!");
        }
        return true;
    }
}
